/* -*- C++ -*- */

/**
 *	@class Peer_Connector
 *
 *	@brief Active Connection Logic
 *
 *	This object is used to ...
 *
 *	@note Attempts at zen rarely work.
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>, (C) 2006
 *
 */
 
#ifndef Peer_Connector_H
#define Peer_Connector_H

#include "ace/Connector.h"
#include "ace/SOCK_Connector.h"

// local includes
#include "ISE.h"
#include "Peer_Handler.h"

namespace Samson_Peer {

//..............................................................................................
//..............................................................................................
//..............................................................................................
class ISE_Export Peer_Connector : public ACE_Connector<Peer_Handler, ACE_SOCK_CONNECTOR>
{
	// = TITLE
	//     Actively establish connections with gatewayd and dynamically
	//     create a new <Peer_Handler> object to communicate with the
	//     gatewayd.
	
	public:
	

		int open (ACE_Reactor * = 0, int = 0);
		// Initialize the <Peer_Connector>.  NOTE:  the arguments are
		// ignored.  They are only provided to avoid a compiler warning
		// about hiding the virtual function ACE_Connector<Peer_Handler,
		// ACE_SOCK_CONNECTOR>::open(ACE_Reactor*, int).


		Peer_Handler *peer_handler() { return peer_handler_; }

	private:
	
		int open_connector (Peer_Handler *&ph, u_short port);
		// Factor out common code for initializing the <Peer_Connector>.

		Peer_Handler *peer_handler_;
		// Consumer <Peer_Handler> that is connected to a gatewayd.

};

}

#endif /* Peer_Connector_H */
