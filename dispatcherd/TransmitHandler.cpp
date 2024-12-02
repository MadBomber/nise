/**
 *	@file TransmitHandler.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "LogLocker.h"

#include "TransmitHandler.h"
#include "EventChannel.h"
#include "Options.h"
#include "DebugFlag.h"
#include "EventHeader.h"

#define  MAX_INSTANT 60

namespace Samson_Peer
{

// ============================================================================
// ============================================================================


TransmitHandler::TransmitHandler(ConnectionRecord * const entity)
{
	ACE_TRACE("TransmitHandler::TransmitHandler");
	if ( this->state_ == UNINITIALIZED ) this->initialize(entity);
	this->msg_queue ()->high_water_mark(Options::instance ()->max_queue_size());
}


// ==========================================================================
/**
 * this put is the main entry so enable filtering
 * returns -1 for failure, postive for success
 */
int
TransmitHandler::put (ACE_Message_Block *event, EventHeader *eh)
{
	ACE_TRACE("TransmitHandler::put(event,header)");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	int retval = -1;


	if ( this->state_ == ConnectionHandler::ESTABLISHED)
	{
		EventHeader *transmit_eh = eh;
		ACE_Message_Block *start_mb = 0;


		/*
		 * Prepare data (filter)
		 */

		if ( this->output_filter_)
		{
			// deep copy the event and header
			start_mb = event->clone();
			transmit_eh->print();
			this->output_filter_->process(start_mb,transmit_eh);
		}
		else if ( event != 0 ) start_mb = event->duplicate (); // shallow-copy


		/*
		 * Prepare header, make a chained message block
		 */

		// TODO:  Warning, all we can do in this version is strip theheader or send it
		//	No header conversion at this time.
		if (transmit_eh  && ( this->header_type_id_ != EventHeader::NOHEADER ))
		{
			size_t HEADER_SIZE = transmit_eh->header_length ();
			if ( HEADER_SIZE > 0)
			{
				transmit_eh->encode();
				char const *temp = transmit_eh->addr ();

				start_mb =  new
					ACE_Message_Block (
						HEADER_SIZE,
						ACE_Message_Block::MB_DATA,
						start_mb,
						0,
						0,
						Options::instance ()->locking_strategy ());
				start_mb->copy(temp,HEADER_SIZE);
			}
		}

		// TODO  This is optimistic, either data or header will be sent...empty is not checked.

		retval = this->put (start_mb);
		if ( retval == -1)
		{
			if (errno == EWOULDBLOCK) // The queue has filled up!
				ACE_ERROR ((LM_ERROR,
					"(%P|%t) PubSubDispatch::send_event -> %p -> gateway is flow controlled, so we're dropping events on %x:%d",
					"put",
					this, this->get_handle()));
			else
				ACE_ERROR ((LM_ERROR,
					"(%P|%t) PubSubDispatch::send_event -> %p -> transmission error to peer %x:%d\n",
					"put",
					this,this->get_handle()));

			transmit_eh->print();

			// If an error occurred, we are responsible for cleaning up.
			start_mb->release();
		}
	} // Active Handler processing

	return retval;
}


// ===========================================================================
// Send an event to a Consumer (may queue if necessary).
// returns -1 on failure, or the number of bytes send or the number of messages queued
// TODO  Evaluate the return

int TransmitHandler::put(ACE_Message_Block *event, ACE_Time_Value *)
{
	ACE_TRACE("TransmitHandler::put");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	ACE_Message_Block *block2send = event;

	// consolidates the MB chain into one block, releases the event MB chain.
	if ( event->cont() != 0 ) block2send = this->consolidate (event);

	if (this->msg_queue ()->is_empty() ) //  || block2send->length() > MAX_INSTANT )
		// Try to send the event *without* blocking!
		return this->nonblk_put(block2send);
	else
	{
		ACE_DEBUG((LM_DEBUG,"(%P|%t) TransmitHandler::put -> queued\n"));

		// If we have queued up events due to flow control then just
		// enqueue and return.
		return this->msg_queue ()->enqueue_tail(block2send, (ACE_Time_Value *) &ACE_Time_Value::zero);
	}
}


// ===========================================================================
// Perform a non-blocking put() of event.  If we are unable to send
// the entire event the remainder is re-queued at the *front* of the
// Event_List.

int TransmitHandler::nonblk_put(ACE_Message_Block *event)
{
	ACE_TRACE("TransmitHandler::nonblk_put");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	size_t bt = 0;
	ssize_t nsent = 0;

	{
		ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
		nsent = this->peer ().send_n(event->rd_ptr(), event->length(), 0, &bt);
	}

	if (nsent <= 0)
	{
		{
			LogLocker log_lock;

			ACE_DEBUG((LM_DEBUG,
				"(%P|%t) TransmitHandler::send-> Error (%d) sent %d of %d bytes to connection on %x|%d  EWOULDBLOCK(%d) errno(%d)\n",
				nsent, bt, event->length(), this, this->get_handle(),
				(errno == EWOULDBLOCK), errno
			));
		}

		if ( errno == EWOULDBLOCK )
		{
			LogLocker log_lock;

			ACE_DEBUG((
					LM_DEBUG,
					"(%P|%t) TransmitHandler::nonblk_put -> queuing activated on %x:%d\n",
					this, this->get_handle()));

			// ACE_Queue in *front* of the list to preserve order.
			if (this->msg_queue ()->enqueue_head(event, (ACE_Time_Value *) &ACE_Time_Value::zero) == -1)
				ACE_ERROR_RETURN((LM_ERROR,
						"(%P|%t) TransmitHandler::nonblk_put -> %p\n",
						"enqueue_head"), -1);

			// Tell ACE_Reactor to call us back when we can send again.
			else if (ACE_Reactor::instance ()->schedule_wakeup(this, ACE_Event_Handler::WRITE_MASK) == -1)
				ACE_ERROR_RETURN((LM_ERROR,
						"(%P|%t) TransmitHandler::nonblk_put -> %p\n",
						"schedule_wakeup"), -1);

			// I am just not sure when this weird condition happens
			nsent = bt;
			event->rd_ptr(bt);

		}
		else
		{
			// Things have gone wrong, let's try to close down and set up a
			// new reconnection by calling handle_close().
			this->state(ConnectionHandler::FAILED);
			this->handle_close();
			return -1;
		}

	}
	else if (nsent < ssize_t(event->length()))
	{
		// Re-adjust pointer to skip over the part we did send.
		event->rd_ptr(nsent);
		errno = EWOULDBLOCK;

		{
			LogLocker log_lock;

			ACE_DEBUG((LM_DEBUG,
				"(%P|%t) TransmitHandler::send-> Partial send %d of %d bytes to connection on %x|%d\n",
				nsent, event->length(), this, this->get_handle()
			));

			// ACE_Queue in *front* of the list to preserve order.
			if (this->msg_queue ()->enqueue_head(event, (ACE_Time_Value *) &ACE_Time_Value::zero) == -1)
				ACE_ERROR_RETURN((LM_ERROR,
					"(%P|%t) TransmitHandler::nonblk_put -> %p\n",
					"enqueue_head"), -1);

			// Tell ACE_Reactor to call us back when we can send again.
			else if (ACE_Reactor::instance ()->schedule_wakeup(this, ACE_Event_Handler::WRITE_MASK) == -1)
				ACE_ERROR_RETURN((LM_ERROR,
					"(%P|%t) TransmitHandler::nonblk_put -> %p\n",
					"schedule_wakeup"), -1);
		}

	}
	else // if (n == length)
	{
		// The whole event is sent, we now decrement the reference count
		// (which deletes itself with it reaches 0).

		// Because we are multi-threaded, we must delete the memory at
		// the lowest possible event....and this is it!

		//  Now delete the entire message chain
		event->release();
		errno = 0;

		if (DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT))
		{
			LogLocker log_lock;

			ACE_DEBUG((LM_DEBUG,
				"(%P|%t) TransmitHandler::send -> sent %d of %d bytes to connection on %x|%d\n",
				nsent, event->length(), this, this->get_handle()
			));
		}

	}

	this->total_bytes_send(nsent);
	return nsent;
}

// ===========================================================================
// Finish sending an event when flow control conditions abate.
// This method is automatically called by the ACE_Reactor.

int TransmitHandler::handle_output(ACE_HANDLE)
{
	ACE_TRACE("TransmitHandler::output");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	ACE_Message_Block *event = 0;

	{
		LogLocker log_lock;

		ACE_DEBUG((
			LM_DEBUG,
			"(%P|%t) TransmitHandler::handle_output -> Receiver signaled 'resume transmission' %d\n",
			this->get_handle()));
	}

	// WIN32 Notes: When the receiver blocked, we started adding to the
	// consumer handler's message Q. At this time, we registered a
	// callback with the reactor to tell us when the TCP layer signalled
	// that we could continue to send messages to the consumer. However,
	// Winsock only sends this notification ONCE, so we have to assume
	// at the application level, that we can continue to send until we
	// get any subsequent blocking signals from the receiver's buffer.

#if defined (ACE_WIN32)
	// Win32 Winsock doesn't trigger multiple "You can write now"
	// signals, so we have to assume that we can continue to write until
	// we get another EWOULDBLOCK.

	// We cancel the wakeup callback we set earlier.
	if (ACE_Reactor::instance ()->cancel_wakeup
			(this, ACE_Event_Handler::WRITE_MASK) == -1)
	ACE_ERROR_RETURN ((LM_ERROR,
					"(%P|%t) TransmitHandler::handle_output -> %p\n",
					"Error in ACE_Reactor::cancel_wakeup()"),
			-1);

	// The list had better not be empty, otherwise there's a bug!
	while (this->msg_queue ()->dequeue_head
			(event, (ACE_Time_Value *) &ACE_Time_Value::zero) != -1)
	{
		switch (this->nonblk_put (event))
		{
			case -1: // Error sending message to consumer.

			{
				// We are responsible for releasing an ACE_Message_Block if
				// failures occur.
				event->release ();

				ACE_ERROR ((LM_ERROR,
								"(%P|%t) TransmitHandler::handle_output -> %p\n",
								"transmission failure"));
				break;
			}
			case 0: // Partial Send - we got flow controlled by the receiver

			{
				ACE_ASSERT (errno == EWOULDBLOCK);
				if (DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT))
				{
					LogLocker log_lock;

					ACE_DEBUG ((LM_DEBUG,
								"TransmitHandler::handle_output -> %D Partial Send due to flow control"
								"- scheduling new wakeup with reactor\n"));
				}

				// Re-schedule a wakeup call from the reactor when the
				// flow control conditions abate.
				if (ACE_Reactor::instance ()->schedule_wakeup (this,ACE_Event_Handler::WRITE_MASK) == -1)
				{
						ACE_ERROR_RETURN ((LM_ERROR,
								"(%P|%t) TransmitHandler::handle_output -> %p\n",
								"Error in ACE_Reactor::schedule_wakeup()"),
								-1);
				}

				// Didn't write everything this time, come back later...
				return 0;
			}

			default: // Sent the whole thing
			{
				LogLocker log_lock;

				ACE_DEBUG ((LM_DEBUG,
								"TransmitHandler::handle_output -> Sent message from message Q, Q size = %d\n",
								this->msg_queue()->message_count ()));
				break;
			}
		}
	}

	// If we drop out of the while loop, then the message Q should be
	// empty...or there's a problem in the dequeue_head() call...but
	// thats another story.
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) queueing deactivated on handle %x:%d\n",
			this, this->get_handle ()
		));
	}

#else /* !defined (ACE_WIN32) */
	// The list had better not be empty, otherwise there's a bug!
	if (this->msg_queue ()->dequeue_head(event, (ACE_Time_Value *) &ACE_Time_Value::zero)
			!= -1)
	{
		switch (this->nonblk_put(event))
		{
		case 0: // Partial send.
			ACE_ASSERT(errno == EWOULDBLOCK);
			{
				LogLocker log_lock;

				ACE_DEBUG((LM_DEBUG,
					"TransmitHandler::handle_output -> %D Partial Send\n"));
			}
			// Didn't write everything this time, come back later...
			break;

		case -1:
			// We are responsible for releasing an ACE_Message_Block if
			// failures occur.
			event->release();
			ACE_ERROR((LM_ERROR,
					"(%P|%t) TransmitHandler::handle_output -> %p\n",
					"transmission failure"));

			/* FALLTHROUGH */
		default: // Sent the whole thing.

			// If we succeed in writing the entire event (or we did not
			// fail due to EWOULDBLOCK) then check if there are more
			// events on the Message_Queue.  If there aren't, tell the
			// ACE_Reactor not to notify us anymore (at least until
			// there are new events queued up).

			{
				LogLocker log_lock;

				ACE_DEBUG((LM_DEBUG,
					"TransmitHandler::handle_output -> QQQ::Sent Message from consumer's Q\n"));
			}

			if (this->msg_queue ()->is_empty())
			{
				ACE_DEBUG((
						LM_DEBUG,
						"(%P|%t) TransmitHandler::handle_output -> queuing deactivated on %x:%d\n",
						this, this->get_handle()));

				if (ACE_Reactor::instance ()->cancel_wakeup(this, ACE_Event_Handler::WRITE_MASK)
						== -1)
					ACE_ERROR((LM_ERROR,
							"(%P|%t) TransmitHandler::handle_output -> %p\n",
							"cancel_wakeup"));
			}
		}
	}
	else
		ACE_ERROR((LM_ERROR, "(%P|%t) TransmitHandler::handle_output -> %p\n",
				"dequeue_head - handle_output called by reactor but nothing in Q"));
#endif /* ACE_WIN32 */
	return 0;
}

// ===========================================================================
ACE_Message_Block *TransmitHandler::consolidate(ACE_Message_Block *event)
{
	ACE_TRACE("TransmitHandler::consolodate_chain");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	// count the number of blocks that are to be transferred

	ACE_Message_Block *current_mb = event;
	ssize_t len = 0;  // total byte count
	while (current_mb != 0)
	{
		len += current_mb->length();
		current_mb = current_mb->cont();
	}

	ACE_Message_Block *ret_mb = 0;
	ACE_NEW_RETURN (  ret_mb,
		ACE_Message_Block (
			len,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
		Options::instance ()->locking_strategy ()),
	0);

	// start the copy
	current_mb = event;
	while (current_mb != 0)
	{
		if ( ret_mb->copy(current_mb->rd_ptr(),current_mb->length()) != 0 )
			ACE_DEBUG((LM_ERROR,"(%P|%t) TransmitHandler::consolodate_chain -> copy error\n"));
		current_mb = current_mb->cont();
	}

	event->release();
	return ret_mb;
}


} // namespace
