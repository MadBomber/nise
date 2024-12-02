/* -*- C++ -*- */

/**
 *	@class Peer_Factory
 *
 * 	@brief Samson Factory Object
 *
 *	This object is used to ...
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */
 


#ifndef Peer_Factory_H
#define Peer_Factory_H

//#include <vld.h>

#include "ace/Service_Config.h"
#include "ace/streams.h"
#include "ace/svc_export.h"

// local includes
#include "ISE.h"
#include "Peer_Acceptor.h"
#include "Peer_Connector.h"
#include "Peer_Stdin_Handler.h"
#include "AppBase.h"

namespace Samson_Peer {

//..............................................................................................
//..............................................................................................
//..............................................................................................
class ISE_Export Peer_Factory : public ACE_Service_Object
{
  // = TITLE
  //     A factory class that actively and/or passively establishes
  //     connections with the gatewayd.
	public:
  // = Dynamic initialization and termination hooks from <ACE_Service_Object>.

		virtual int init (int argc, ACE_TCHAR *argv[]);
		// Initialize the acceptor and connector.

		virtual int fini (void);
		// Perform termination activities.

		virtual int info (ACE_TCHAR **, size_t) const;
		// Return info about this service.

		virtual int handle_signal (int signum, siginfo_t *, ucontext_t *);
		// Handle various signals (e.g., SIGPIPE, SIGINT, and SIGQUIT).

		void embedded(AppBase *eap) { this->embedded_app_ = eap; }

	private:
		Peer_Acceptor acceptor_;
		// Pointer to an instance of our <Peer_Acceptor> that's used to
		// accept connections and create Consumers.

		Peer_Connector connector_;
		// An instance of our <Peer_Connector>.  Note that one
		// <Peer_Connector> is used to establish <Peer_Handler>s for both
		// Consumers and Suppliers.

		ofstream *log_ostream_;
		// The ouput file stream for Logging

		Peer_Stdin_Handler *stdin_handler_;
		// this will be the default processor for stdin

		AppBase *embedded_app_;
		// this is when I am called from MASES
};

//ACE_SVC_FACTORY_DECLARE (Peer_Factory);
ACE_FACTORY_DECLARE (ISE, Peer_Factory)

}

#endif /* PEER_H */
