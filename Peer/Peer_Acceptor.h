/* -*- C++ -*- */

/**
 *	@class Peer_Acceptor
 *
 *	@brief Passive Connection Logic
 *
 *	This object is used to ...
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef Peer_Acceptor_H
#define Peer_Acceptor_H

#include "ace/Acceptor.h"
#include "ace/SOCK_Acceptor.h"

// local includes
#include "ISE.h"
#include "Peer_Handler.h"

namespace Samson_Peer {


//..............................................................................................
class ISE_Export Peer_Acceptor : public ACE_Acceptor<Peer_Handler, ACE_SOCK_ACCEPTOR>
{
  // = TITLE
  //     Passively accept connections from gatewayd and dynamically
  //     create a new <Peer_Handler> object to communicate with the
  //     gatewayd.
	public:
 		// = Initialization and termination methods.
		Peer_Acceptor (void);
		// Default initialization.

		int start (u_short);
		//  the <Peer_Acceptor>.

		int close (void);
		// Terminate the <Peer_Acceptor>.

		virtual int make_svc_handler (Peer_Handler *&);
		// Factory method that creates a <Peer_Handler> just once.

		Peer_Handler *peer_handler() { return peer_handler_; }

	private:
		int open_acceptor (u_short port);
		// Factor out common code for initializing the <Peer_Acceptor>.

		Peer_Handler *peer_handler_;
		// Pointer to <Peer_Handler> allocated just once.

		ACE_INET_Addr addr_;
		// Our acceptor addr.

		typedef ACE_Acceptor<Peer_Handler, ACE_SOCK_ACCEPTOR> inherited;
		// Used to call the base class
};

}

#endif /* Peer_Acceptor_H */

