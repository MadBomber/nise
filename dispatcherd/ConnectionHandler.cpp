/**
 *	@file ConnectionHandler.cpp
 *
 *  @brief Service Handler for active connections
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#define ISE_BUILD_DLL

#include "ConnectionHandler.h"
#include "EventChannel.h"
#include "PubSubDispatch.h"
#include "Reaction.h"
#include "RouterStats.h"
#include "Service_ObjMgr.h"
#include "DispatcherIdentity.h"
#include "ModelIdentity.h"
#include "CommandIdentity.h"
#include "DebugFlag.h"
#include "LogLocker.h"
#include "ChannelFilterMgr.h"
#include "LogLocker.h"

#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include <netinet/tcp.h>

#include "ace/SString.h"


#if !defined (__ACE_INLINE__)
#include "ConnectionHandler.inl"
#endif /* __ACE_INLINE__ */

namespace Samson_Peer {

// ==========================================================================
int
ConnectionHandler::initialize (ConnectionRecord * const entity )
{
	ACE_TRACE("ConnectionHandler::initialize");

	//ACE_Guard<ACE_Recursive_Thread_Mutex> locker(mutex_);

	// ConnectionRecord defines the handlers type (e.g., active/passive...send/recv/both...)
	this->entity_ = entity;

	// This is the foreign key from the ConnectionRecord
	this->connection_id_ = entity->id_; // this is the key

 	this->local_addr_.set( (unsigned short) 0 );

 	const char *server_name = entity->host_.c_str()[0] == '\0' ? ACE_DEFAULT_SERVER_HOST : entity->host_.c_str();
	this->remote_addr_.set (entity->port_, server_name);


	this->state_ = ConnectionHandler::IDLE;
	this->timeout_  = 1;
	this->timer_id_ = 0;
	this->commanded_close_ = false;
	this->remote_addr0_ = this->remote_addr_;

	this->header_type_id_ = EVH.lookup(entity->header_.c_str());

	// Channel Filters
	input_filter_dll_ = entity->input_filter_;
	output_filter_dll_ = entity->output_filter_;


	return 1;
}



// ==========================================================================
//  Clean up theis connection properly.
ConnectionHandler::~ConnectionHandler()
{
	ACE_TRACE("ConnectionHandler::~ConnectionHandler");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	//---------------------------------------------------------------------------------------------------------
	// remove the timer
	if (this->timer_id_ >0)
		ACE_Reactor::instance ()->cancel_timer (this->timer_id_);

	// remove this from the table of connection handlers
	this->entity_->ch_set_.erase(this);


	if ( ! this->command_role() )
	{
		// remove this from the Dispather-to-[Model,Dispatcher,Command] tables
		// save the runtime-stats if this is a Model
		{
			ModelIdentityRecord sir;
			if ( D2M_TABLE::instance()->findCHID (this->get_handle(), &sir))
			{
				this->save_stats (sir.jid, sir.mid);
				D2M_TABLE::instance ()->unbindCHID (this->get_handle());
			}
		}
		D2D_TABLE::instance ()->unbindCHID (this->get_handle());

		// unload the filters
		if ( input_filter_dll_.length() > 0)
		{
			this->input_filter_ = CH_FILTER_MGR::instance ()->unload (input_filter_dll_);
		}

		if ( output_filter_dll_.length() > 0)
		{
			this->output_filter_ = CH_FILTER_MGR::instance ()->unload (output_filter_dll_);
		}
	}
	else
	{
		D2C_TABLE::instance ()->unbindCHID (this->get_handle());
		ACE_DEBUG ((LM_DEBUG,"(%P|%t|%T) ConnectionHandler::~ConnectionHandler() => Command Handler destroyed\n"));
	}

	//---------------------------------------------------------------------------------------------------------
	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) <<<<<<< "
			"~ConnectionHandler(%d:%x) ->  (%d left) END\n",
			this->get_handle(), this, this->entity_->ch_set_.size()
		));
	}

}


// ==========================================================================
// Handle shutdown of the ConnectionHandler object.
// This overrides the deletion of active connection to support reconnects

int
ConnectionHandler::handle_close (ACE_HANDLE h, ACE_Reactor_Mask)
{
	ACE_TRACE("ConnectionHandler::handle_close");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	if (this->command_role ())
	{
		ACE_DEBUG ((LM_DEBUG,"(%P|%t|%T) ConnectionHandler::handle_close(%d) => Command Handler processed\n",h));
	}


	//---------------------------------------------------------------------------------------------------------
	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) >>>>>>> "
			"ConnectionHandler::handle_close(%d:%x) ->  CTable %d on Port %d  START\n",
			h, this,
			this->entity_->id_, this->entity_->port_
		));
	}

	int result = 0;

	// Restart the active connection, or remove it
	if ( !this->passive () && !this->commanded_close_ )
	{
		this->state (ConnectionHandler::FAILED);
		result = EVENT_CHANNEL_MGR::instance ()->reinitiate_connection (this);
	}
	else
	{
		if ( !this->passive () ) EVENT_CHANNEL_MGR::instance ()->cancel_connection (this);
		this->state(ConnectionHandler::DISCONNECTING);

		// keep this from being called prior to destruction
		ACE_Reactor_Mask mask =
				ACE_Event_Handler::DONT_CALL | ACE_Event_Handler::ALL_EVENTS_MASK;
		ACE_Reactor::instance ()->remove_handler (this, mask);

		this->destroy ();   // this will trigger the destruction
	}

	//---------------------------------------------------------------------------------------------------------
	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) <<<<<<< "
			"ConnectionHandler::handle_close(%d:%x) -> CTable %d on Port %d  Result %d  END\n",h, this,
			this->entity_->id_, this->entity_->port_, result
		));
	}

	return result;
}

// ==========================================================================
// Called only on connection failure!
int ConnectionHandler::handle_input(ACE_HANDLE)
{
	ACE_TRACE("ConnectionHandler::handle_input");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker(mutex_);

	// Do not set FAILED state at here, just at real failed place.

	char buf[BUFSIZ];
	ssize_t received = this->peer ().recv(buf, sizeof buf);

	switch (received)
	{
	case -1:
		this->state(ConnectionHandler::FAILED);
		ACE_ERROR_RETURN(
				(
					LM_ERROR,
					"(%P|%t|%T) ConnectionHandler::handle_input -> Peer has failed unexpectedly on %d\n",
					this->connection_id()), -1);
		/* NOTREACHED */
	case 0:
		this->state(ConnectionHandler::FAILED);
		ACE_ERROR_RETURN(
				(
					LM_ERROR,
					"(%P|%t|%T) ConnectionHandler::handle_input -> Peer has shutdown unexpectedly on %d\n",
					this->connection_id()), -1);
		/* NOTREACHED */
	default:
		ACE_ERROR_RETURN(
				(
					LM_ERROR,
					"(%P|%t|%T) ConnectionHandler::handle_input -> IGNORED: Consumer is erroneously sending input to %d\n"
						"data size = %d\ndata:\n%s\n\n",
					this->connection_id(), received, buf), 0); // Return 0 to identify received data successfully.
		/* NOTREACHED */
	}

	return 0;
}

// ==========================================================================
// Upcall from the <ACE_Acceptor> or <ACE_Connector> that delegates
// control to our ConnectionHandler.
//
//	Intersting things to note.
//	The EventChannel object completes the initialization, but it calls
//	this->complete_connection at the end.  (Which returns initialization data)
//

int
ConnectionHandler::open (void *)
{
	ACE_TRACE("ConnectionHandler::open");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	// TODO  Explain this ??
	ACE_Reactor *TPReactor = ACE_Reactor::instance ();
	this->reactor (TPReactor);

	// Turn on non-blocking I/O.
	if (this->peer ().enable (ACE_NONBLOCK) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::open -> %p\n", "enable"), -1);

	// get local and remote addresses for later use.
	else if (this->peer ().get_local_addr (this->local_addr_) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::open -> Failed to get local address?\n"),-1);

	else if (this->peer ().get_remote_addr (this->remote_addr_) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::open -> Failed to get remote address?\n"),-1);


	// Register ourselves to receive input events iff we are not transmit only
	if ( this->proxy_role() != 'T' )
	{
		if (ACE_Reactor::instance ()->register_handler(this, ACE_Event_Handler::READ_MASK) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::open -> %p\n", "register_handler"), -1);
	}
	else
		ACE_DEBUG ((LM_INFO, "(%P|%t|%T) ConnectionHandler::open(%d|%d|%x) -> No READ_MASK\n",
				this->connection_id_, this->get_handle(), this));

	// Turn off Nagle !!!!
	if (this->entity_->tcp_nodelay) this->set_nodelay ();

	// Set the send/receive buffer sizes (0 for default)
	this->set_buffer_sizes();

	// Our state is now "established."
	this->state (ConnectionHandler::ESTABLISHED);

	// Restart the timeout to 1.
	this->timeout (1);

	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		char faddr_buf[MAXHOSTNAMELEN];
		char addr_buf[MAXHOSTNAMELEN];
		this->local_addr ().addr_to_string (faddr_buf, sizeof faddr_buf);
		this->remote_addr ().addr_to_string (addr_buf, sizeof addr_buf);

		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
				"(%P|%t|%T) ConnectionHandler::open(%d|%d|%x) -> local %s remote %s\n",
				this->connection_id_, this->get_handle(), this, faddr_buf, addr_buf));
	}

	return this->complete_connection ();
}


// ==========================================================================
int
ConnectionHandler::complete_connection ()
{
	ACE_TRACE("ConnectionHandler::complete_connection");

	int result = 0;

	// The Samson Dispatcher is the one who initiates the hello exchange,
	//  which is used to fill the routing information
	if (this->header_type_id_ == EventHeader::SAMSONHEADER)
	{
		result = PUBSUB_DISPATCH::instance()->send_hello(this);
	}

	// Load the filters
	if ( input_filter_dll_.length() > 0)
	{
		this->input_filter_ = CH_FILTER_MGR::instance ()->load (input_filter_dll_.c_str());
	}

	if ( output_filter_dll_.length() > 0)
	{
		this->output_filter_ = CH_FILTER_MGR::instance ()->load (output_filter_dll_.c_str());
	}

	// This is a command channel.
	if (this->command_role ())
	{
		CommandIdentityRecord entity;
		entity.chid = int(this->get_handle ());
		entity.ch = this;
		D2C_TABLE::instance ()->bind(&entity);
		ACE_DEBUG ((LM_DEBUG,"(%P|%t|%T) ConnectionHandler::complete_connection(%d) => Command Handler processed\n",this->get_handle ()));
	}


	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) ConnectionHandler::complete_connection for (%d|%d|%x) cid(%d) command(%s) samson(%s:%d)\n",
			this->connection_id_,
			this->get_handle (),
			this,
			this->connection_id (),
			((this->command_role ())?"true":"false"),
			((this->header_type_id_ == EventHeader::SAMSONHEADER)?"true":"false"),
			this->header_type_id_
		));
	}


	return result;
}


// ==========================================================================
EventHeader *
ConnectionHandler::create_header(EventHeader *eh)
{
	ACE_TRACE("ConnectionHandler::create_header");

	EventHeader *temp;
	if ( (temp = EVH.get (this->header_type_id_)) == 0 )
		ACE_ERROR ( (LM_ERROR, "(%P|%t|%T) ConnectionHandler::create_header -> Allocation Error\n"));

    int HEADER_SIZE =  eh->header_length();
	if ( this->header_type_id_ == eh->header_type() && HEADER_SIZE > 0 )
		ACE_OS::memcpy(temp->addr(), eh->addr(), HEADER_SIZE);
    else
		temp->transform(eh);
    return temp;
}




// ==========================================================================
// Sets the buffer sizes.
void
ConnectionHandler::set_buffer_sizes (void)
{
	if ( this->entity_->recv_buff > 0 )
	{
		unsigned int rb = this->entity_->recv_buff;
		if (this->peer ().set_option (SOL_SOCKET, SO_RCVBUF, &(rb), sizeof(rb) ) == -1)
			ACE_ERROR ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::set_buffer_sizes -> %p\n", "set_option"));
	}

	if ( this->entity_->send_buff > 0 )
	{
		unsigned int sb = this->entity_->send_buff;
		if (this->peer ().set_option (SOL_SOCKET, SO_SNDBUF, &(sb), sizeof(sb) ) == -1)
			ACE_ERROR ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::set_buffer_sizes ->  %p\n", "set_option"));
	}
}


// ==========================================================================
// Turns off the Nagel deleay.
void
ConnectionHandler::set_nodelay (void)
{
	struct protoent *p = ACE_OS::getprotobyname ("tcp");
    int one = 1;

	if (p && this->peer ().set_option (
    			p->p_proto,
    			TCP_NODELAY,
			(char *)& one,
			sizeof (one)))
		ACE_ERROR ((LM_ERROR, "(%P|%t|%T) ConnectionHandler::set_nodelay -> %p\n", "set_nodelay"));
}


// ==========================================================================
// ==========================================================================
void
ConnectionHandler::status (std::stringstream &my_result, bool header_)
{
	char local_addr_string[MAXHOSTNAMELEN];
	ACE_OS::strcpy(local_addr_string,this->local_addr_.get_host_addr());

	char remote_addr_string[MAXHOSTNAMELEN];
	ACE_OS::strcpy(remote_addr_string,this->remote_addr_.get_host_addr());

 	if ( header_ )
	{
		my_result
    			<< "Current Connection List (Both Active and Passive)" << std::endl
        		<< "(CID  ConnHndlr  Hndl)         Local                 Remote        C D S" << std::endl
        		<< "----- ---------- ----- --------------------- --------------------- - - -" << std::endl;
	}

	ACE_HANDLE theHandle = this->get_handle ();

	//  "%5d %5d %15.15s:%5hu %15.15s:%5hu %c %c %1d",

	my_result
		<< std::setw(5) << this->connection_id_ << " "
		<< std::hex << this << std::dec << " "
		<< std::setw(5) << theHandle << " "
		<< std::setw(15) << local_addr_string  << ":"
		<< std::setw(5) << this->local_addr_.get_port_number() << " "
		<< std::setw(15) << remote_addr_string << ":"
		<< std::setw(5) << this->remote_addr_.get_port_number() << " "
		<< std::setw(1) << this->entity_->connection_type_ << " "
		<< std::setw(1) << this->entity_->proxy_role_ << " "
		<< std::setw(1) << this->state_  << " "
		<< std::endl;

	// reset timeout
	this->timeout (1);
}



// ==========================================================================
// ==========================================================================
void
ConnectionHandler::stats (std::stringstream &my_report, bool header_, int type)
{

 	if ( header_ )
	{
		my_report
			<< "                     |-             delta  (sec)                 -|" << std::endl
			<< " ID   #bytes   #msgs  mean     std dv    #       min        max    " << std::endl
			<< "----- -------- ----- -------- -------- ------ ---------- ----------" << std::endl;
	}

	//---------------------------------------------------------


	//my_report << std::setw(5) << this->connection_id_;
	my_report << std::setw(5) << this->get_handle();
	recv_stats.print(my_report, "recv", type);
	//recv_stats.reset();
	my_report << std::endl;

	my_report << "     ";
	send_stats.print(my_report, "send", type);
	//send_stats.reset();
	my_report << std::endl;
}


// ==========================================================================
// ==========================================================================
void
ConnectionHandler::save_stats (unsigned int job_id, unsigned int peer_id)
{

	ACE_TRACE("ConnectionHandler::save_stats");

	int total_bytes, total_msgs;
	double mean, stddev, delta_min, delta_max;

	recv_stats.compute(mean, stddev, total_bytes, total_msgs, delta_min, delta_max );
	SAMSON_OBJMGR::instance ()->DispatcherStats (job_id, peer_id,'R', total_bytes, total_msgs, mean, stddev, delta_min, delta_max);

	send_stats.compute(mean, stddev, total_bytes, total_msgs, delta_min, delta_max );
	SAMSON_OBJMGR::instance ()->DispatcherStats (job_id, peer_id,'S', total_bytes, total_msgs, mean, stddev, delta_min, delta_max);

	int count;
	process_time.compute(count, mean, stddev, delta_min, delta_max );
	SAMSON_OBJMGR::instance ()->DispatcherStats (job_id, peer_id, 'P', 0, count, mean, stddev, delta_min, delta_max);

}


// ==========================================================================
// Re-calculate the current retry timeout delay using exponential
// backoff.  Returns the original timeout (i.e., before the
// re-calculation).

unsigned int
ConnectionHandler::timeout (void)
{
	unsigned int old_timeout = this->timeout_;
	this->timeout_ *= 2;

	if (this->timeout_ > this->entity_->max_retry_timeout_)
		this->timeout_ = this->entity_->max_retry_timeout_;

	return old_timeout;
}


// ==========================================================================
// Restart connection asynchronously when timeout occurs.

int
ConnectionHandler::handle_timeout (const ACE_Time_Value &,
                                    const void *)
{
	// ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
	{
		LogLocker log_lock;

  		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t|%T) ConnectionHandler::handle_timeout -> starting reconnect CID(%d|%d) with timeout(%d)\n",
        	this->connection_id (),
        	this->get_handle (),
			this->timeout_));
	}

	this->timer_id_ = 0;

	// Delegate the re-connection attempt to the Event Channel.
	EVENT_CHANNEL_MGR::instance ()->initiate_connection (this,1);

	// TODO  should I return the above result?
	return 0;
}

// ==========================================================================
// Restart connection asynchronously when timeout occurs.

int
ConnectionHandler::schedule_reconnect (void)
{
	ACE_Time_Value const timeout (this->timeout ());
	if ( (this->timer_id_=ACE_Reactor::instance ()->schedule_timer (this, 0, timeout)) == -1)
		ACE_ERROR_RETURN ((LM_ERROR,
			"(%P|%t|%T) ConnectionHandler::schedule_reconnect -> %p\n",
			"schedule_timer"),
			-1);

	return 0;
}



} // namespace
