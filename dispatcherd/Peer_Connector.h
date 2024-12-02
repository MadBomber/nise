/**
 *	@file Peer_Connector.h
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *	@brief Performs active network connection
 *
 */

#ifndef PEER_CONNECTOR_H
#define PEER_CONNECTOR_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Connector.h"
#include "ace/SOCK_Connector.h"
#include "ace/Recursive_Thread_Mutex.h"

#include "ISEExport.h"
#include "ConnectionHandler.h" // NOTE: not using pointer or reference, so cannot forward declare


namespace Samson_Peer {

// ==========================================================================================
class ISE_Export Peer_Connector : public ACE_Connector<ConnectionHandler, ACE_SOCK_CONNECTOR>
{
  // = TITLE
  //     A concrete factory class that setups connections to peerds
  //     and produces a new ConnectionHandler object to do the dirty
  //     work...
public:
  Peer_Connector (void) {};

  // Initiate (or reinitiate) a connection on the ConnectionHandler.
  int initiate_connection (ConnectionHandler *,
                           ACE_Synch_Options & = ACE_Synch_Options::synch);
 
protected:
	
	ACE_Recursive_Thread_Mutex mutex_;


};

} // namespace

#endif
