/**
 *	@file Peer_Acceptor.cpp
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


#include "Peer_Acceptor.h"
#include "ConnectionTable.h"
#include "Options.h"
#include "DebugFlag.h"

namespace Samson_Peer {

// ============================================================================
Peer_Acceptor::Peer_Acceptor (ConnectionRecord *entity)
{
	ACE_TRACE("Peer_Acceptor::Peer_Acceptor");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	this->sim_entity_ = entity;
	this->listen_addr_.set (entity->port_, entity->host_.c_str());
	this->bound_2_handler = false;
}

// ============================================================================
// Overload of the ACE_Acceptor protected method to create a new service handler
//
// Returns -1 on failure, else 0.
//
int
Peer_Acceptor::make_svc_handler (ConnectionHandler *&ch)
{
	ACE_TRACE("Peer_Acceptor::make_svc_handler");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	if ( (ch = CONNECTION_TABLE::instance ()->make_connection_handler (this->sim_entity_)) == 0 ) return -1;

	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Acceptor::make_svc_handler(%d:%x)\n",
				ch->get_handle(),ch
		));

	return 0;
}

// ============================================================================
// Overload of the ACE_Acceptor protected method to accept the new connection
//
// Returns -1 on failure, else 0.  (not in ACE Documentation)
//
int
Peer_Acceptor::accept_svc_handler (ConnectionHandler *ch)
{
	ACE_TRACE("Peer_Acceptor::accept_svc_handler");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	int result= this->inherited::accept_svc_handler (ch);
	// For now I will assume that the connection_id is set by the constructor.

	if (result == 0)
	{
		if (ch->peer ().get_remote_addr (this->connection_addr_) == -1) return -1;
		if (ch->peer ().get_local_addr (this->listen_addr_) == -1) return -1;

		// Set the remote address of our connected Peer.
		ch->remote_addr (this->connection_addr_);
		this->bound_2_handler = true;

		if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Acceptor::accept_svc_handler(%d:%x)\n",
					ch->get_handle(),ch
			));

		// Insert this into the connection set.
		this->sim_entity_->ch_set_.insert(ch);

	}
	return result;
}

// ========================================================================
// Overload of the ACE_Acceptor public method to open the new connection
// Open the contained PEER_ACCEPTOR object to begin listening, and register
// with the specified reactor for accept events.
//
// Returns -1 on failure, else 0.
//
int
Peer_Acceptor::open (u_short port)
{
	ACE_TRACE("Peer_Acceptor::open");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	// I need to protect from re-entrance.  If a handle exists,
	// then this routine has been called previously.

	if ( (int) this->get_handle () != -1 )  return 0;


	if ( this->listen_addr_.get_port_number() == 0 )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Acceptor::open -> Port was not pre-set\n"));
		this->listen_addr_.set (port);
	}

	// Call down to the <Acceptor::open> method.
	if (this->inherited::open (
			this->listen_addr_,
			ACE_Reactor::instance (),
			Options::instance ()->blocking_semantics ()
            ) == -1)
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Acceptor::open -> Error on port %d\n",this->listen_addr_.get_port_number()));
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Acceptor::open -> %p\n", "inherited open"), -1);
	}
	else if (this->acceptor ().get_local_addr (this->listen_addr_) == -1)
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Acceptor::open -> %p\n", "get_local_addr"), -1);

	else if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) Peer_Acceptor::open(%d) -> Listening for connection on port %d\n",
			this->get_handle (), this->listen_addr_.get_port_number ()));

	return 0;
}






// ============================================================================
// ============================================================================
void
Peer_Acceptor::status (std::stringstream &my_result, bool header_)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	if ( header_ )
	{
		my_result
			<< "Passive Listener or Acceptor List" << std::endl
			<< " CID      Local                   Remote          R #ch Bound" << std::endl
			<< "----- --------------------- --------------------- - --- -----" << std::endl;
	}

//		"%5d %15s:%5hd %15s:%5hu  (%c) %3d  %5s\n",
	my_result
		<< std::setw(5)  << this->sim_entity_->id_ << " "
		<< std::setw(15) << this->listen_addr_.get_host_addr() << ":"
		<< std::setw(5)  << this->listen_addr_.get_port_number() << " "
		<< std::setw(15) << this->connection_addr_.get_host_addr() << ":"
		<< std::setw(5)  << this->connection_addr_.get_port_number() << " "
		<< std::setw(1)  << this->sim_entity_->proxy_role_ << " "
		<< std::setw(3)  << this->sim_entity_->ch_set_.size() << " "
		<< std::setw(5)  << (this->bound_2_handler?"true":"false")
		<< std::endl;
}


} // namespace
