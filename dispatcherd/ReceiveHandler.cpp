/**
 *	@file ReceiveHandler.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include "ReceiveHandler.h"
#include "EventChannel.h"
#include "EventHeaderFactory.h"
#include "Options.h"
#include "ConnectionTable.h"
#include "Service_ObjMgr.h"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "ChannelFilterMgr.h"
#include "LogLocker.h"

#include "ace/High_Res_Timer.h"

// At this juncture header data sizes are not all that large
#define SUSPICIOUS_HEADER 1000

namespace Samson_Peer {

// ============================================================================
// CHFactory<ConnectionHandler,ReceiveHandler> ReceiveHandler::myFactory;

// ============================================================================

ReceiveHandler::ReceiveHandler (ConnectionRecord * const entity )
{
	ACE_TRACE("ReceiveHandler::ReceiveHandler");

	if ( this->state_ == UNINITIALIZED ) this->initialize(entity);
	this->msg_queue ()->high_water_mark (0);


	this->recv_action = &ReceiveHandler::recv_header;
	if ( this->header_type_id_ == EventHeader::NOHEADER )
	{
		this->recv_action = &ReceiveHandler::recv_noheader;
	}

	this->data_frag_ = 0;
	this->header_frag_ = 0;
	this->header_recvd_ = 0;
}

ReceiveHandler::~ReceiveHandler ()
{
	ACE_TRACE("ReceiveHandler::~ReceiveHandler");
}



// ============================================================================
//  The NoHeader receive reads up to the MAX_MSG_SIZE and routes it on
//  Crude, but works :(
int
ReceiveHandler::recv_noheader (ACE_Message_Block *&theEvent, EventHeader *&theHeader)
{
	ACE_TRACE("ReceiveHandler::recv_noheader");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	int MAX_MSG_SIZE = this->read_buff();
    MAX_MSG_SIZE = (MAX_MSG_SIZE!=0)?MAX_MSG_SIZE:1024;

#if 0
    {
        LogLocker log_lock;

    	ACE_DEBUG ((LM_DEBUG,
				"(%P|%t|%T) ReceiveHandler::recv_noheader(%d|%d|%x) -> buffer size(%d)\n",
				this->connection_id_, this->get_handle (), this, MAX_MSG_SIZE));
    }
#endif

    // Allocate the header for routing purposes

    if ( (theHeader = EVH.get (this->header_type_id_)) == 0 )
        	ACE_ERROR (
            	(LM_ERROR,
                "(%P|%t|%T) ReceiveHandler::recv_noheader -> EventHeader Allocation Error\n"));


	//  This is the data block...allocate it to max length
	ACE_NEW_RETURN (
		theEvent,
		ACE_Message_Block (
			MAX_MSG_SIZE,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
			Options::instance ()->locking_strategy ()),
		-1);



	// Read up the MAX_MSG_SIZE blocks
	ssize_t data_received =
			this->peer ().recv (theEvent->base (), MAX_MSG_SIZE);
	theEvent->wr_ptr (data_received);


	int result = 0;

	switch (data_received)
	{
		case -1:
			if (errno == EWOULDBLOCK) result = -1;
			/* FALLTHROUGH */;

		case 0: // Premature EOF.
			{
				LogLocker log_lock;

				ACE_DEBUG ((LM_ERROR, "(%P|%t|%T) ReceiveHandler::recv_noheader -> data_received=%d with errno=%d)\n",
						data_received, errno));
			}
			delete theHeader;
			theEvent->release ();
		break;

		default:

			// Set Header
			theHeader->connection_id(this->connection_id_);
			theHeader->handle(this->get_handle ());
			theHeader->data_length(data_received);

			if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
			{
				LogLocker log_lock;

				ACE_DEBUG ((LM_DEBUG,
							"(%P|%t|%T) ReceiveHandler::recv_noheader(%d|%d|%x) -> total bytes read(%d)\n",
							this->connection_id_, this->get_handle (), this, data_received));
				ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) theEvent->rd_ptr(), theEvent->length());
			}

			result = data_received;
	}
	return result;
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

int
ReceiveHandler::recv_header (ACE_Message_Block *&theEvent, EventHeader *&theHeader)
{
	ACE_TRACE("ReceiveHandler::recv_header");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	static unsigned int count = 0; // counter for debugging
	int result = 0;  // return result
	int stage_flag = 0;  // used to what sections we are going through

	count++;

	// -----------------------------------------------------------------------
	if (this->header_frag_ == 0)
	{
		//-------------------------------------------------------------
		// Stage 1: allocate a header
		if ( (this->header_frag_ = EVH.get (this->header_type_id_)) == 0 )
		{
			ACE_ERROR ((LM_ERROR,
				"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> EventHeader Allocation Error\n",
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
#if 0
		//if ( this->header_recvd_ != 0 )
		if ( this->header_recvd_ != 0 && DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) )
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_ERROR,"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> (Previous) short header read %d of %d\n",
				this->get_handle (), this, count, this->header_recvd_, HEADER_SIZE));
			ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) this->header_frag_->addr(), this->header_recvd_);
			hex_dump = true;
		}
#endif
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
				LogLocker log_lock;

				ACE_DEBUG ((LM_ERROR,
						"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> (Repeat) short header read %d of %d (%d:%d) \n",
						this->get_handle (), this, count, this->header_recvd_, HEADER_SIZE, errno, errno == EWOULDBLOCK ));
				ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) this->header_frag_->addr(), this->header_recvd_);
			}
			else if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
			{
				LogLocker log_lock;
				ACE_DEBUG ((LM_ERROR,
					"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> (Repeat) short header read %d of %d (%d:%d) \n",
					this->get_handle (), this, count, this->header_recvd_, HEADER_SIZE, errno, errno == EWOULDBLOCK ));
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

		// Fill in the hidden header details
		this->header_frag_->connection_id(this->connection_id_);
		this->header_frag_->handle(this->get_handle ());


#if 0
		if (!this->header_frag_->verify () ||
			 (this->header_frag_->header_type()==EventHeader::SAMSONHEADER
					&& !SAMSON_OBJMGR::instance ()->verifyRunID (static_cast<SamsonHeader *>(this->header_frag_)->run_id ())) )
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> Header failed to verify.\n",
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
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> CID(%d) will recv %d(%d) bytes of data.\n",
			this->get_handle (), this, count,
			this->header_frag_->connection_id(),
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
					Options::instance ()->locking_strategy ()),
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


		// Note:  stage_flag should be 0x000f at this point!

		switch (data_received)
		{
			case -1:
				if (errno == EWOULDBLOCK) result = -1;
				stage_flag |= 0x0080;  // Fragment?
			break;

			case 0:
				errno = EWOULDBLOCK;
				result=-1;
				stage_flag |= 0x0040;  // Fragment?
				break;

			default:
				// Set the write pointer at 1 past the end of the event.
				this->data_frag_->wr_ptr (data_received);

				if (data_received != data_bytes_left_to_read)
				{
#if 0
					if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
					{
						LogLocker log_lock;

						ACE_DEBUG ((LM_DEBUG,
							"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> Did not get whole message! %d of %d (%d of %d) ->\n",
							this->get_handle (), this, count,
							data_received, data_bytes_left_to_read, this->data_frag_->length(), total_data_bytes
						));
						this->header_frag_->print();
					}
#endif
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
						LogLocker log_lock;
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
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d) -> recv %d bytes of data, Data Length = %d (Negative)\n",
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

		stage_flag |= 0x0800;  // Cleanup

	}


	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) ReceiveHandler::recv_header(%d|%x|%d)-> result=%d Rcvd(%d)  H:(%d:%d)+D:(%d:%d) (H:%x+D:%x) (H:%x+D:%x) Stage %x\n",
			this->get_handle (), this, count,
			result,
			data_received,
			this->header_recvd_, HEADER_SIZE,
			(this->data_frag_)?this->data_frag_->length():0,
			total_data_bytes,
			theHeader, theEvent,
			this->header_frag_, this->data_frag_,
			stage_flag
		));
	}

	return result;
}


// ============================================================================
/**
 * Receive various types of input (e.g., Peer event from the network)
 *
 * This is our implementation of the ACE_Event_Handler::handle_input  method
 *
 * Per: Ch 3.3 in C++ Network Programming, Volume 2: Systematic Reuse with ACE and Frameworks
 *
 * Return value 0 indicates that the reactor should continue to detect and dispatch the registered event for this event handler
 * (and handle if it's an I/O event). This behavior is common for event handlers that process multiple instances of an
 * event, for example, reading data from a socket as it becomes available.
 *
 * Return value greater than 0 also indicates that the reactor should continue to detect and dispatch the registered event
 * for this event handler. Additionally, if a value > 0 is returned after processing an I/O event, the reactor will
 * dispatch this event handler on the handle again before the reactor blocks on its event demultiplexer. This feature
 * enhances overall system fairness for cooperative I/O event handlers by allowing one event handler to perform a limited amount of computation,
 * then relinquish control to allow other event handlers to be dispatched before it regains control again.
 *
 * Return value -1 instructs the reactor to stop detecting the registered event for this event handler (and handle if it's an I/O event).
 * Before the reactor removes this event handler/handle from its internal tables, it invokes the handler's handle_close() hook method,
 * passing it the ACE_Reactor_Mask value of the event that's now unregistered. This event handler may remain registered for other events
 * on the same, or a different, handle; it's the handler's responsibility to track which event(s) it's still registered.
 *
 */
int
ReceiveHandler::handle_input (ACE_HANDLE hndl)
{
	ACE_TRACE("ReceiveHandler::handle_input");

	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	ACE_Message_Block *recvd_data = 0;
	EventHeader *recvd_header = 0;
	int result = 0;
	int nrecvd = 0;
	bool processed = false;
	double process_sec = 0.0;
	double read_sec = 0.0;
	double filter_sec = 0.0;

	//---------------------------------------------------------------------------------------------------------
	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"\n(%P|%t|%T) >>>>>>> "
			"ReceiveHandler::handle_input(%d|%d|%x) START\n",
			this->connection_id_, hndl, this
		));
	}

	errno = 0;

	{
		ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
		ACE_High_Res_Timer timer;
		timer.start ();
		nrecvd = (this->*recv_action)(recvd_data, recvd_header);
		timer.stop ();
		ACE_Time_Value measured;
		timer.elapsed_time (measured);
		read_sec = measured.usec () * 1.0e-6;
	}

	if ( nrecvd > 0 )
	{

#if 0
		if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,"(%P|%t|%T) ReceiveHandler::handle_input(%d|%x) -> recvd %d bytes\n", hndl, this, nrecvd));
		}
#endif

		if ( recvd_header != 0  )
		{

			result = 0;

			// Process here if there is an input filter
			// if ( this->input_filter_ ) this->input_filter_->process(recvd_data, recvd_header);


			// ask the Event Channel manager to process the message and track the time required
			this->total_bytes_recv (nrecvd);
  			ACE_High_Res_Timer timer;

  			if (this->input_filter_ )
  			{
  				ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
  	 			timer.start ();
  	 			this->input_filter_->process(recvd_data, recvd_header);
  				timer.stop ();
  				ACE_Time_Value measured;
  				timer.elapsed_time (measured);
  				filter_sec = measured.usec () * 1.0e-6;
  			}

  			timer.start ();
			int presult = EVENT_CHANNEL_MGR::instance ()->process(this, recvd_data, recvd_header);
			timer.stop ();
			processed = true;
			ACE_Time_Value measured;
			timer.elapsed_time (measured);
			process_sec = measured.usec () * 1.0e-6;
			this->process_time.sample (process_sec);

			// This needs to return 0, but if the return result is not 0, then I want to fail the connection
			if ( presult != 0 )
			{
				this->state (ConnectionHandler::FAILED);
				if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT))
				{
					LogLocker log_lock;

					ACE_DEBUG ((LM_DEBUG,
						"(%P|%t|%T) ReceiveHandler::handle_input(%d|%d|%x) -> Connection(%d) is closing\n",
						this->connection_id_, hndl, this
					));
				}
				 result = -1;
			}
		}
		else
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG,"(%P|%t|%T) ReceiveHandler::handle_input(%d|%d|%x) -> error empty header, %d bytes rcvd (H:%x+D:%x)\n",
					this->connection_id_, hndl, this, nrecvd,recvd_header,recvd_header));
			if ( recvd_data ) ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) recvd_data->base(), nrecvd);
			ACE_DEBUG ((LM_ERROR,"\n%s\n",CONNECTION_TABLE::instance ()->status_connections().c_str()));
			result = 0;
		}
	}
	else if ( nrecvd == 0 )
	{
		LogLocker log_lock;

		// Client has disconnected...let higher levels decide what to do.
		this->state (ConnectionHandler::FAILED);
		/*
		ACE_DEBUG ((LM_ERROR,
			"(%P|%t|%T) ReceiveHandler::handle_input(%d|%x) -> Peer closed for CID(%d)\n",
			hndl, this, this->connection_id ()
			));
		*/
		result = -1;
	}
	else if ( nrecvd < 0 )
	{
		// A short-read, we'll come back and finish it up later on!
		if (errno == EWOULDBLOCK)
		{
			//LogLocker log_lock;
			//ACE_DEBUG ((LM_ERROR,"(%P|%t|%T) ReceiveHandler::handle_input(%d|%x) -> short read\n",hndl,this));
			result = 0;
		}
		else // A weird problem occurred, shut down and start again.
		{
			LogLocker log_lock;

			this->state (ConnectionHandler::FAILED);
			ACE_DEBUG ((LM_ERROR,
				"(%P|%t|%T) ReceiveHandler::handle_input(%d|%d|%x) -> Failing Connection\n",
				this->connection_id_, hndl, this
				));
			result = -1;
		}
	}

	//---------------------------------------------------------------------------------------------------------
	if (DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) || result != 0 )
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) <<<<<<<< "
			"ReceiveHandler::handle_input(%d|%d|%x) -> Result:%d  Processed: %s (%f) Read(%f) Filter(%f)END\n\n",
			this->connection_id_, hndl, this, result, (processed?"Yes":"No"), process_sec, read_sec, filter_sec
		));
	}

	return result;
}

// ==========================================================================
// ==========================================================================
void
ReceiveHandler::status (std::stringstream &my_result, bool header_)
{
	char local_addr_string[MAXHOSTNAMELEN];
	ACE_OS::strcpy(local_addr_string,this->local_addr_.get_host_addr());

	char remote_addr_string[MAXHOSTNAMELEN];
	ACE_OS::strcpy(remote_addr_string,this->remote_addr_.get_host_addr());

 	if ( header_ )
	{
		my_result
    			<< "Current Connection List (Both Active and Passive)" << std::endl
        		<< "(CID  ConnHndlr Hndl)         Local                 Remote       " << std::endl
        		<< "----- --------- ----- --------------------- ---------------------" << std::endl;
	}

	ACE_HANDLE theHandle = this->get_handle ();

	my_result << std::setw(5) << this->connection_id_ << " ";
	my_result << std::hex << static_cast<ConnectionHandler *>(this) << std::dec << " ";
	my_result << std::setw(5) << theHandle << " ";
	my_result << std::setw(15) << local_addr_string  << ":";
	my_result << std::setw(5) << this->local_addr_.get_port_number() << " ";
	my_result << std::setw(15) << remote_addr_string << ":";
	my_result << std::setw(5) << this->remote_addr_.get_port_number() << " ";


	my_result << std::hex << this->data_frag_ << std::dec << " ";
	my_result << std::hex << this->header_frag_ << std::dec << " ";
	my_result << std::setw(5) << this->header_recvd_;
	my_result << std::endl;
}

// ============================================================================
// CHFactory<ConnectionHandler,Thr_ReceiveHandler> Thr_ReceiveHandler::myFactory;

} // namespace
