/* -*- C++ -*- */

/**
 *	@file Peer_Handler.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *	@brief Handles Network events
 *
 */

#define ISE_BUILD_DLL

#include <boost/crc.hpp>  // for boost::crc_32_type

#include "Peer_Handler.h"

#include "Options.h"
#include "DebugFlag.h"
#include "Base_ObjMgr.h"
#include "SharedAppMgr.h"
#include "SamsonHeader.h"
#include "ace/Log_Msg.h"

namespace Samson_Peer {

// ========================================================================================
// ========================================================================================
// ========================================================================================
/**
 *
 * @param
 * @return
 */
Peer_Handler::Peer_Handler (void)
{
	// Set the high water mark of the <ACE_Message_Queue>.  This is used
	// to exert flow control.
	this->msg_queue ()->high_water_mark (Options::instance ()->max_queue_size ());
	this->application_id_ = -1;

	// This is the interface to the attached Samson Application
	this->samson_app_ = 0;

	// recv
	this->data_frag_ = 0;
	this->header_frag_ = 0;
	this->header_recvd_ = 0;

	this->debug_ = false;
}


// ........................................................................................
/**
 *
 * @param app_
 */
void
Peer_Handler::register_application (SharedAppMgr *app_)
{
	this->samson_app_ = app_;
}

// ........................................................................................
/**
 *
 * @param a
 * @return
 */
int
Peer_Handler::open (void *a)
{
	ACE_TRACE("Peer_Handler::open");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	//if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) ||
	//	DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT) ||
	//	DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG) ||
	//	DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
	{
		ACE_DEBUG ((LM_DEBUG,
				ACE_TEXT ("(%P|%t) Peer_Handler::open handle = %d\n"),
				this->peer ().get_handle ()));
	}

    // TODO  Explain this ??
    ACE_Reactor *TPReactor = ACE_Reactor::instance ();
    this->reactor (TPReactor);

	// Register ourselves to receive input events.
	if (ACE_Reactor::instance ()->register_handler(this, ACE_Event_Handler::READ_MASK) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Handler::open -> %p\n", "register_handler"), -1);


	// Call down to the base class to activate and register this handler
	// with an <ACE_Reactor>.
	else if (this->inherited::open (a) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "%p\n","open"), -1);

	// Turn on non-blocking I/O.
	else if (this->peer ().enable (ACE_NONBLOCK) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "%p\n", "enable"), -1);


	// If there are events left in the queue, make sure we enable the
	// <ACE_Reactor> appropriately to get them sent out.
	else if (this->msg_queue ()->is_empty () == 0
		&& ACE_Reactor::instance ()->schedule_wakeup
		(this, ACE_Event_Handler::WRITE_MASK) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "%p\n", "schedule_wakeup"), -1);

	return 0;
}


// ........................................................................................
/**
 * Transmit a Message_Block chain to Peer
 *
 * @param start_mb A Message_Block chain to be sent
 * @return the total bytes sent or -1 for failure
 */
int
Peer_Handler::transmit (ACE_Message_Block *start_mb, bool log_it)
{
	ACE_TRACE("Peer_Handler::transmit");

	// set for one message debugging
	this->debug_ = log_it;

	ACE_Message_Block *block2send = start_mb;

	// consolidates the MB chain into one block, releases the event MB chain.
	if ( start_mb->cont() != 0 ) block2send = this->consolidate (start_mb);

	int result = 0;
	int n = block2send->length();




	// Header needs to be complete (and encoded)  before entering here!!!!
	// I am expecting a chained block  (header and data )

	if ( (result = this->put (block2send)) == -1)
	{
		if (errno == EWOULDBLOCK) // The queue has filled up!
			ACE_ERROR ((LM_ERROR, "%p\n", "connection is flow controlled, so we're dropping events"));
		else
			ACE_ERROR ((LM_ERROR, "%p\n", "transmission failure in transmit()"));
		start_mb->release ();
		result = -1; //
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT) || this->debug_)
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Handler::transmit total mb length = %d, total sent =%d\n", n, result));
	}

	// reset it!
	this->debug_ = false;

	return result;
}


// ........................................................................................
/**
 * Send an event to a peer (may block if necessary).
 *
 * @param mb  Chained Message_Block with header and data to be sent
 * @param tv  Time Value (not used)
 *
 * @return the total bytes sent
 */
int
Peer_Handler::put (ACE_Message_Block *mb, ACE_Time_Value *)
{
	if (this->msg_queue ()->is_empty ())
		// Try to send the event *without* blocking!
		return this->nonblk_put (mb);
	else
		// If we have queued up events due to flow control then just
		// enqueue and return.
		return this->msg_queue ()->enqueue_tail
				(mb, (ACE_Time_Value *) &ACE_Time_Value::zero);
}


// ........................................................................................
/**
 * Perform a non-blocking <put> of event MB.  If we are unable to send
 * the entire event the remainder is re-queue'd at the *front* of the
 * Message_Queue.
 *
 * @param mb Chained Message_Block with header and data to be sent
 *
 * @return the total bytes sent
 */
int
Peer_Handler::nonblk_put (ACE_Message_Block *mb)
{
	// Try to send the event.  If we don't send it all (e.g., due to
	// flow control), then re-queue the remainder at the head of the
	// <ACE_Message_Queue> and ask the <ACE_Reactor> to inform us (via
	// <handle_output>) when it is possible to try again.

	ssize_t n = this->send (mb);

	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) || this->debug_)
	{
		ACE_DEBUG((LM_DEBUG,
			"(%P|%t) Peer_Handler::nonblk_put -> sent %d of %d bytes \n",
			n, mb->length()
		));
	}

	if (n == -1)
		// -1 is returned only when things have really gone wrong (i.e.,
		// not when flow control occurs).
		return -1;

	else if (errno == EWOULDBLOCK)
	{
		// We didn't manage to send everything, so requeue.
		ACE_DEBUG ((LM_DEBUG,
					ACE_TEXT ("queueing activated on handle %d to app id %d\n"),
					this->get_handle (),
					this->application_id_));

		// Re-queue in *front* of the list to preserve order.
		if (this->msg_queue ()->enqueue_head
				(mb,
				(ACE_Time_Value *) &ACE_Time_Value::zero) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "%p\n", "enqueue_head"), -1);
		// Tell ACE_Reactor to call us back when we can send again.
		if (ACE_Reactor::instance ()->schedule_wakeup
				(this, ACE_Event_Handler::WRITE_MASK) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "%p\n", "schedule_wakeup"), -1);
		return 0;
	}
	else
		return n;
}



// ........................................................................................
/**
 * Main interface to send
 *
 * @param event a Message_Block chain
 *
 * @return total number of bytes sent
 */
ssize_t
Peer_Handler::send (ACE_Message_Block *event)
{
	ACE_TRACE("Peer_Handler::send");


	ssize_t n =  this->peer ().send_n(event->rd_ptr(), event->length());

	if (DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT) || this->debug_ )
	{
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) Peer_Handler::send -> sent %d of %d bytes\n",
			n, event->length()
		));
	}

	int result = 0;
	if (n <= 0)
	{
		result = EWOULDBLOCK ? 0 : n;
	}
	else if (n < ssize_t(event->length()))
	{
    	// Re-adjust pointer to skip over the part we did send.
		event->rd_ptr (n);
		errno = EWOULDBLOCK;
		result=n;
	}
	else // if (n == length)
	{
		// The whole event is sent, we now decrement the reference count
		// (which deletes itself with it reaches 0).
		event->release ();
		errno = 0;
		result = n;
	}
	return result;
}


/**
 * Finish sending a event when flow control conditions abate.  This
 * method is automatically called by the ACE_Reactor.
 *
 * @param  is ignored
 *
 * @return 0 for success
 */
int
Peer_Handler::handle_output (ACE_HANDLE)
{
	ACE_TRACE("Peer_Handler::handle_output");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	ACE_Message_Block *mb = 0;

	if (this->msg_queue ()->dequeue_head
		(mb,
			(ACE_Time_Value *) &ACE_Time_Value::zero) != -1)
	{
		switch (this->nonblk_put (mb))
		{
			case 0:           // Partial send.
				ACE_ASSERT (errno == EWOULDBLOCK);
				// Didn't write everything this time, come back later...
				break;
				/* NOTREACHED */

			case -1:
				// Caller is responsible for freeing a ACE_Message_Block if
				// failures occur.
				mb->release ();
				ACE_ERROR ((LM_ERROR, "%p\n", "transmission failure in handle_output"));
				/* FALLTHROUGH */

			default: // Sent the whole thing.
				// If we succeed in writing the entire event (or we did not
				// fail due to EWOULDBLOCK) then check if there are more
				// events on the <ACE_Message_Queue>.  If there aren't, tell
				// the <ACE_Reactor> not to notify us anymore (at least
				// until there are new events queued up).

				if (this->msg_queue ()->is_empty ())
				{
					ACE_DEBUG ((LM_DEBUG, "queue now empty on handle %d to app id %d\n", this->get_handle (), this->application_id_));

					if (ACE_Reactor::instance ()->cancel_wakeup (this, ACE_Event_Handler::WRITE_MASK) == -1)
						ACE_ERROR ((LM_ERROR, "%p\n", "cancel_wakeup"));
				}
		}
		return 0;
	}
	else
	// If the list is empty there's a bug!
		ACE_ERROR_RETURN ((LM_ERROR, "%p\n", "dequeue_head"), 0);
}







// ........................................................................................
// Action that receives events from the Gateway.
//
int
Peer_Handler::await_events (void)
{
	ACE_TRACE("Peer_Handler::await_events");

	// Empty Message block pointer to receive, this will be allocated in recv
	ACE_Message_Block *mb = 0;

	// Empty EventHeader to receive
	SamsonHeader *sh = 0;

	ssize_t n = this->recv (mb, sh);

	switch (n)
	{
		case 0:
			//ACE_Reactor::instance ()->end_reactor_event_loop ();
			ACE_ERROR_RETURN ((LM_ERROR, "Peer_Handler::await_events -> Peer has closed down\n"), -1);
		/* NOTREACHED */

		case -1:
			if (errno == EWOULDBLOCK)
				// A short-read, we'll come back and finish it up later on!
				return 0;
			else
				ACE_ERROR_RETURN ((LM_ERROR, "Peer_Handler::await_events -> %p\n","recv"), -1);
		/* NOTREACHED */

		default:
		{
			// Potentially a valid event,  verify it
			ACE_UINT32 crc32 = 0;
			if (mb && mb->length() > 0)
			{
				boost::crc_32_type  result;
				result.process_bytes( mb->base(), mb->length() );
				crc32 = result.checksum();
				if ( sh->crc32() != crc32 )
				{
					ACE_DEBUG ((LM_ERROR, "(%P|%t) Peer_Handler::await_events -> CRC32 Checksum Error  %x != %x\n" ,sh->crc32(), crc32));

					// this is a job ending condition
					// TODO  send  error to the run controller and let it take care of the shutdown.
					this->samson_app_->SamApp()->requestJobStatus();
					ACE_OS::sleep(3);
					this->samson_app_->SamApp()->stopSimulation();

				}
			}


			// We got a valid event, so let's process it now!

			//ACE_Trace::stop_tracing();

			int retval = 0;
			if (this->samson_app_ != 0 )
				retval = samson_app_->handle_event ( mb, sh);
			if (mb) mb->release ();
			delete sh;

			//ACE_Trace::start_tracing();

			return retval;
		}
	}
}



// ........................................................................................
// Receive various types of input (e.g., Peer event from the gatewayd,
// as well as stdio).
//
// need to return 0, to let go of the current input
int
Peer_Handler::handle_input (ACE_HANDLE sd)
{
	ACE_TRACE("Peer_Handler::handle_input");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	int retval = -1;

	// Perform the appropriate action depending on the state we are in.
	retval = this->await_events ();

	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Handler::handle_input(%d) -> retval %d\n", sd, retval));
	}

	// All of the routines return the number of bytes they handled, but I need to return 0
	// in order to allow the next receive to take place

	if ( retval < 0 )
	{
		ACE_Reactor::instance ()->end_reactor_event_loop ();
	}

	return 0;
}

// ........................................................................................
// Periodically send events via ACE_Reactor timer mechanism.

int
Peer_Handler::handle_timeout (const ACE_Time_Value &, const void *)
{
// Shut down the handler.
	return this->handle_close ();
}

// ........................................................................................
Peer_Handler::~Peer_Handler (void)
{
	// Shut down the handler.
	this->handle_close ();

}

// ........................................................................................
// Handle shutdown of the Peer object.

int
Peer_Handler::handle_close (ACE_HANDLE, ACE_Reactor_Mask)
{
	ACE_TRACE("Peer_Handler::handle_close");

	ACE_HANDLE h = this->get_handle (); // not sure why

	if (h != ACE_INVALID_HANDLE)
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) ||
			DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT) ||
			DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG) ||
			DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
		{
			ACE_DEBUG ((LM_DEBUG, ACE_TEXT ("(%P|%t) Peer_Handler::handle_close(%d)\n"), h));
		}

		ACE_Reactor_Mask mask =
				ACE_Event_Handler::DONT_CALL | ACE_Event_Handler::ALL_EVENTS_MASK;
		ACE_Reactor::instance ()->remove_handler (this, mask);

		// Close down the peer.
		this->peer ().close ();

	}
	return 0;
}





// ============================================================================
/**
 *  Receive an Event from a Supplier.  Handles fragmentation.
 *
 * The event returned from recv consists of two parts:
 *
 * 1. The Address part, contains the "virtual" routing id.
 *
 * 2. The Data part, which contains the actual data to be forwarded.
 *
 * The reason for having two parts is to shield the higher layers
 * of software from knowledge of the event structure.
 *
 * Returns the total number of bytes read or
 * 0 - to disconnect
 * <0 - for error unless  errno is set to EWOULDBLOCK, which indicates a partial read
 *
 */

// At this juncture header data sizes are not all that large
#define SUSPICIOUS_HEADER 1000

int
Peer_Handler::recv (ACE_Message_Block *&theEvent, SamsonHeader *&theHeader)
{
	ACE_TRACE("Peer_Handler::recv");

	static unsigned int count = 0; // counter for debugging
	int result = 0;  // return result
	int stage_flag = 0;  // used to what sections we are going through

	count++;

	// -----------------------------------------------------------------------
	if (this->header_frag_ == 0)
	{
		//-------------------------------------------------------------
		// Stage 1: allocate a header
		if ( (this->header_frag_ = new SamsonHeader() ) == 0 )
		{
			ACE_ERROR ((LM_ERROR,
				"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> EventHeader Allocation Error\n",
				this->get_handle (), this, count
			));
			return -2;
		}

		stage_flag |= 0x0001;  // header allocated
		this->header_recvd_ = 0;  // this will ensure a header read

	}

	//-------------------------------------------------------------
	// Stage 2: read the header
	// Note: For now we are using all "constant length" headers

	bool hex_dump = false;

	const int HEADER_SIZE = this->header_frag_->header_length();
	if ( this->header_recvd_ != HEADER_SIZE )
	{
		//if ( this->header_recvd_ != 0 )
		if ( this->header_recvd_ != 0 && DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) )
		{
			ACE_DEBUG ((LM_ERROR,"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> (Previous) short header read %d of %d\n",
				this->get_handle (), this, count, this->header_recvd_, HEADER_SIZE));
			ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) this->header_frag_->addr(), this->header_recvd_);
			hex_dump = true;
		}

		char *HEADER_ADDR = this->header_frag_->addr() + this->header_recvd_;
		int HEADER_READ_SIZE = HEADER_SIZE - this->header_recvd_;

		/* Note from "ace/SOCK_IO.h" on the recv method
		 *
		 * Errors are reported by -1 and 0 return values.  If the operation times out, -1 is returned with errno == ETIME.
		 *
		 * for non-blocking sockets,-1 will be returned with errno == EWOULDBLOCK if no action is
		 * immediately possible.
		 *
		 * If it succeeds the number of bytes transferred is returned.
		 */

		errno = 0;
		this->header_recvd_ += peer ().recv (HEADER_ADDR, HEADER_READ_SIZE);

		if ( this->header_recvd_ != HEADER_SIZE )
		{
			if (hex_dump)
			{
				ACE_DEBUG ((LM_ERROR,
						"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> (Repeat) short header read %d of %d (%d:%d) \n",
						this->get_handle (), this, count, this->header_recvd_, HEADER_SIZE, errno, errno == EWOULDBLOCK ));
				ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) this->header_frag_->addr(), this->header_recvd_);
			}

			result = 0; // returning zero indicates disconnect
			if (this->header_recvd_ >0 && errno==0)
			{
				errno = EWOULDBLOCK; // crude hack!
				result = -1;
			}
			else if (errno==EWOULDBLOCK)
			{
				result = -1;
			}
			return result;
		}

		// Convert the header into host byte order so that we can access
		// it directly without having to repeatedly muck with it...
		this->header_frag_->encoded(true);
		this->header_frag_->decode ();


#if 0
		if (!this->header_frag_->verify () ||
			 (this->header_frag_->header_type()==EventHeader::SAMSONHEADER
					&& !SAMSON_OBJMGR::instance ()->verifyRunID() ( static_cast<SamsonHeader *>(this->header_frag_)->job_id ())) )
		{
			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> Header failed to verify.\n",
				this->get_handle (), this, count ));
			this->header_frag_->print();

			EVENT_CHANNEL_MGR::instance ()->print ();
			return -3;
		}
#endif

		stage_flag |= 0x0002;  // header read
	}


	// TODO Validate header here!

	/**
	 * Header read is complete, not get the data by:
	 * 1. Get the length of the data that follows the header
	 * 2. Allocate a messageblock of the proper size
	 */

	ssize_t total_data_bytes = this->header_frag_->data_length();

#if 0
	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) || total_data_bytes > SUSPICIOUS_HEADER || hex_dump )
	{
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> recv  %d(%d) bytes of data.\n",
			this->get_handle (), this, count,
			this->header_frag_->data_length(),
			total_data_bytes
			));
		//this->header_frag_->print();
	}
#endif

	/**
	 * Receive the data
	 */
	ssize_t data_received = 0;

	if ( total_data_bytes > 0 )
	{
		// Allocate space for the data, or handle zero/bad data length
		if (this->data_frag_ == 0 )
		{
			//-------------------------------------------------------------
			// Stage 3: Allocate Space for the Event Data

			// No existing fragment...
			ACE_NEW_RETURN (this->data_frag_,
				ACE_Message_Block (
					total_data_bytes,
					ACE_Message_Block::MB_DATA,
					0,
					0,
					0,
					0),
					-2);

			stage_flag |= 0x0004;  // data block allocated
		}


		//-------------------------------------------------------------
		// Stage 4: Read the Event Data
		ssize_t data_bytes_left_to_read = total_data_bytes - this->data_frag_->length();

		data_received =
			!data_bytes_left_to_read
			? 0 // peer().recv() should not be called when data_bytes_left_to_read is 0.
			: this->peer ().recv (this->data_frag_->wr_ptr (), data_bytes_left_to_read);


		stage_flag |= 0x0008;  // data block read

		switch (data_received)
		{
			case -1:
				if (errno == EWOULDBLOCK) result = -1;
				break;

			case 0:
				errno = EWOULDBLOCK;
				result=-1;
				break;

			default:
				// Set the write pointer at 1 past the end of the event.
				this->data_frag_->wr_ptr (data_received);

				if (data_received != data_bytes_left_to_read)
				{
					if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
					{
						ACE_DEBUG ((LM_DEBUG,
							"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> Did not get whole message! %d of %d (%d of %d) ->\n",
							this->get_handle (), this, count,
							data_received, data_bytes_left_to_read, this->data_frag_->length(), total_data_bytes
						));
						this->header_frag_->print();
					}
					errno = EWOULDBLOCK;
					// Inform caller that we didn't get the whole event.
					result = -1;
					stage_flag |= 0x0020;  // Fragment
				}
				else  // this is a full event, cleanup and leave
				{
					//-------------------------------------------------------------
					// Stage 5a: Cleanup and transfer complete
#if 0
					if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
					{
						ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) this->data_frag_->rd_ptr(), this->data_frag_->length());
					}
#endif
					// Transfer to the proper return values, memory will be released elsewhere
					theEvent = this->data_frag_;
					theHeader = this->header_frag_;

					// Reset the local storage
					this->data_frag_ = 0;
					this->header_frag_ = 0;

					// Pass back the total number of bytes read
					result = this->header_recvd_ + total_data_bytes;  // handle partial reads?

					// Reset the header count (cause we are not using MessageBlocks!)
					this->header_recvd_ = 0;

					stage_flag |= 0x0010;  // Cleanup
				}

		}
	}
	else if (total_data_bytes < 0)
	{
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> recv %d bytes of data, Data Length = %d (Negative)\n",
			this->get_handle (), this, count,
			this->header_frag_->data_length(), total_data_bytes
		));
		this->header_frag_->print();

		delete this->header_frag_;
		this->header_frag_ = 0;
		this->header_recvd_ = 0;
		result = -2;
	}
	else if (total_data_bytes == 0)
	{
		//-------------------------------------------------------------
		// Stage 5b: Cleanup and transfer complete  (Special case, just header!)

		// fill the return data
		theEvent = 0;
		theHeader = this->header_frag_;

		// Reset the local storage (it will be released elsewhere)
		this->data_frag_ = 0;
		this->header_frag_ = 0;
		result = this->header_recvd_;
		this->header_recvd_ = 0;

		stage_flag |= 0x00080;  // Cleanup

	}


	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
	{
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) ReceiveHandler::recv_header(%d|0x%x|%d) -> result=%d H:(%d:%d)+D:(%d:%d) (H:0x%x+D:0x%x) (H:0x%x+D:0x%x) Stage 0x%x\n",
			this->get_handle (), this, count,
			result,
			this->header_recvd_, HEADER_SIZE, data_received, total_data_bytes,
			theHeader, theEvent,
			this->header_frag_, this->data_frag_,
			stage_flag
		));
	}

	return result;
}

// ===========================================================================
ACE_Message_Block *Peer_Handler::consolidate(ACE_Message_Block *event)
{
	ACE_TRACE("Peer_Handler::consolodate_chain");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

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
			0),
	0);

	// start the copy
	current_mb = event;
	while (current_mb != 0)
	{
		if ( ret_mb->copy(current_mb->rd_ptr(),current_mb->length()) != 0 )
			ACE_DEBUG((LM_ERROR,"(%P|%t) Peer_Handler::consolodate_chain -> copy error\n"));
		current_mb = current_mb->cont();
	}

	event->release();
	return ret_mb;
}



}  // namespace
