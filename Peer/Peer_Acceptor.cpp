/* -*- C++ -*- */

/**
 *  @file: Peer_Acceptor.cpp
 * 
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "Peer_Acceptor.h"
#include "DebugFlag.h"

namespace Samson_Peer {

int
Peer_Acceptor::start (u_short port)
{
  // This object only gets allocated once and is just recycled
  // forever.
	ACE_NEW_RETURN (peer_handler_, Peer_Handler, -1);

	this->addr_.set (port);

	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Peer_Acceptor::start(%d)\n",port));
	}

  // Call down to the <Acceptor::open> method.
	if (this->inherited::open (this->addr_) == -1)
		ACE_ERROR_RETURN ((LM_ERROR,
						   ACE_TEXT ("%p\n"),
						   ACE_TEXT ("open")),
	-1);
	else if (this->acceptor ().get_local_addr (this->addr_) == -1)
		ACE_ERROR_RETURN ((LM_ERROR,
						   ACE_TEXT ("%p\n"),
						   ACE_TEXT ("get_local_addr")),
	-1);
	else
		ACE_DEBUG ((LM_DEBUG,
					ACE_TEXT ("(%P|%t) Peer_Acceptor::start -> accepting at port %d\n"),
					this->addr_.get_port_number ()));
	return 0;
}


// ========================================================================================
Peer_Acceptor::Peer_Acceptor (void)
	: peer_handler_ (0)
{
}


// ========================================================================================
int
Peer_Acceptor::close (void)
{
  // Will trigger a delete.
	if (this->peer_handler_ != 0)
		this->peer_handler_->destroy ();

  // Close down the base class.
	return this->inherited::close ();
}


// ========================================================================================
// Note how this method just passes back the pre-allocated
// <Peer_Handler> instead of having the <ACE_Acceptor> allocate a new
// one each time!
int
Peer_Acceptor::make_svc_handler (Peer_Handler *&sh)
{
	sh = this->peer_handler_;
	return 0;
}

}

