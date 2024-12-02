/* -*- C++ -*- */

/**
 *	@file Peer_Connector.cpp
 *
 *	@brief Active Connection Logic
 *
 *	This ...
 * 
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "Peer_Connector.h"
#include "Options.h"
#include "DebugFlag.h"

namespace Samson_Peer {

// ========================================================================================
int
Peer_Connector::open_connector (Peer_Handler *&peer_handler, u_short port)
{
	// This object only gets allocated once and is just recycled forever.
	ACE_NEW_RETURN (peer_handler,
					Peer_Handler,
					-1);

	ACE_INET_Addr addr (port, Options::instance ()->host ());

	if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG,
			ACE_TEXT ("(%P|%t) Peer_Connector::open_connector(%d,%d) to host (%s) %s\n"),
			peer_handler->get_handle(),
			addr.get_port_number (),
			Options::instance ()->host (),
			addr.get_host_name ()
		));
	}

	if (this->connect (peer_handler, addr) == -1)
	{
		ACE_ERROR_RETURN ((LM_ERROR,
						   ACE_TEXT ("(%P|%t) Peer_Connector::open_connector -> %p\n"),
						   ACE_TEXT ("connect")),
							-1);
	}
	else
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG) )
		{
			ACE_DEBUG ((LM_DEBUG,
					ACE_TEXT ("(%P|%t) Peer_Connector::open_connector -> connected to %s:%d\n"),
					addr.get_host_name (),
					addr.get_port_number ()));
		}
	}
	return 0;
}

// ........................................................................................
int
Peer_Connector::open (ACE_Reactor *, int)
{
	this->peer_handler_ = 0;

	if (Options::instance ()->enabled (Options::CONNECTOR)
		   && this->open_connector (this->peer_handler_,
									Options::instance ()->port ()) == -1)
		return -1;

	return 0;
}

}
