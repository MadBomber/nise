/**
 *      @file Peer_Connector.cpp
 *
 *      @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "Peer_Connector.h"
#include "ConnectionHandler.h"
#include "DebugFlag.h"

namespace Samson_Peer {

// ===========================================================================
/*
Peer_Connector::Peer_Connector (void)
{
}
*/

// ===========================================================================
// Initiate (or reinitiate) a connection to the ConnectionHandler.

int
Peer_Connector::initiate_connection (ConnectionHandler *connection_handler,
                                                   ACE_Synch_Options &synch_options)
{
	ACE_TRACE("Peer_Connector::initiate_connection");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	
	char faddr_buf[MAXHOSTNAMELEN];
	char addr_buf[MAXHOSTNAMELEN];

	// If connection is established....don't do it again!!!

	if ( connection_handler->state () != ConnectionHandler::ESTABLISHED )
	{

		// Mark ourselves as idle so that the various iterators will ignore
		// us until we are reconnected.
		connection_handler->state (ConnectionHandler::IDLE);

		ACE_INET_Addr temp( (unsigned short) 0 );  // connect with any address or port
		connection_handler->local_addr (temp);

		// We check the remote addr second so that it remains in the addr_buf.
		//   What does this mean??? I took it from the original...but why
		if (connection_handler->local_addr ().addr_to_string (faddr_buf, sizeof faddr_buf) == -1
				|| connection_handler->remote_addr ().addr_to_string (addr_buf, sizeof addr_buf) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Connector::initiate_connection ->  %p\n",
				"can't obtain peer's address"), -1);


		if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
		{
			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) Peer_Connector::initiate_connection -> initiating connection from %s to %s\n",
				faddr_buf, addr_buf
		));
	}

	// Try to connect to the Peer.
	if (this->connect (
		connection_handler,
		connection_handler->remote_addr (),
		synch_options,
		connection_handler->local_addr ()) == -1)
	{
		if (errno != EWOULDBLOCK)
		{
			connection_handler->state (ConnectionHandler::FAILED);
			if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
			{
				ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) Peer_Connector::initiate_connection -> %p "
					" connection err from %s to %s (Errno = %d)\n", "",
					faddr_buf, addr_buf, errno));
#ifdef WIN32
				ACE_DEBUG ((LM_DEBUG, "WSAError = %d",WSAGetLastError() ));
#endif
			}

			return -1;
		}
		else
		{
			connection_handler->state (ConnectionHandler::CONNECTING);
			if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
			{
				connection_handler->local_addr ().addr_to_string (faddr_buf, sizeof faddr_buf);

				ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) Peer_Connector::initiate_connection -> still connecting to %s\n",
					addr_buf));
			}
        }
	}
	else  // connection was made
	{
		connection_handler->state (ConnectionHandler::ESTABLISHED);

		if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
		{
			connection_handler->local_addr ().addr_to_string (faddr_buf, sizeof faddr_buf);
    			connection_handler->remote_addr ().addr_to_string (addr_buf, sizeof addr_buf);

			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) Peer_Connector::initiate_connection -> connected from %s to %s on %d\n",
				faddr_buf,
				addr_buf,
				connection_handler->get_handle ()));
    	}
	}
}
else  // Connection was established
{
		connection_handler->local_addr ().addr_to_string (faddr_buf, sizeof faddr_buf);
		connection_handler->remote_addr ().addr_to_string (addr_buf, sizeof addr_buf);

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) Peer_Connector::initiate_connection -> Already connected to %s from %s on %d\n",
			addr_buf,
			faddr_buf,
			connection_handler->get_handle ()));
}

return 0;
}

} // namespace
