/* -*- C++ -*- */

/**
 *	@class Peer_Handler
 *
 *	@brief Peer Connection Handling Logic
 *
 *	This object is used to ...
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef Peer_Handler_H
#define Peer_Handler_H

#include "ISE.h"

#include "ace/Svc_Handler.h"
#include "ace/SOCK_Stream.h"
#include "ace/Null_Condition.h"
#include "ace/Null_Mutex.h"
#include "ace/Thread_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"


#include "EventHeaderFactory.h"
#include "SamsonHeader.h"


#define MAX_PAYLOAD_SIZE 1024

namespace Samson_Peer {

//forward declaration
class  SharedAppMgr;

// -----------------------------------------------------------------------------------------
class ISE_Export Peer_Handler : public ACE_Svc_Handler<ACE_SOCK_STREAM, ACE_MT_SYNCH>
{
  // = TITLE
  //     Handle Peer events arriving from a Gateway.
	public:
		// = Initialization and termination methods.

		Peer_Handler (void);
		// Initialize the peer.

		~Peer_Handler (void);
		// Shutdown the Peer.

		virtual int open (void * = 0);
		// Initialize the handler when called by
		// <ACE_Acceptor::handle_input>.

		virtual int handle_input (ACE_HANDLE);
		// Receive and process peer events.

		virtual int put (ACE_Message_Block *, ACE_Time_Value *tv = 0);
		// Send a event to a gateway (may be queued if necessary due to flow
		// control).

		virtual int handle_output (ACE_HANDLE);
		// Finish sending a event when flow control conditions abate.

		virtual int handle_timeout (const ACE_Time_Value &,
									const void *arg);
		// Periodically send events via <ACE_Reactor> timer mechanism.

		virtual int handle_close (ACE_HANDLE = ACE_INVALID_HANDLE,
								  ACE_Reactor_Mask = ACE_Event_Handler::ALL_EVENTS_MASK);
		// Perform object termination.

		void register_application (SharedAppMgr *app_);
		// Register this application handler

		int transmit (ACE_Message_Block *start_mb, bool log_it);
		// Transmit <mb> to the gatewayd.

		EventHeaderFactory EVH;

	protected:
		typedef ACE_Svc_Handler<ACE_SOCK_STREAM, ACE_MT_SYNCH> inherited;

		virtual int recv (ACE_Message_Block *&, SamsonHeader *&);
		// Receive an Peer event from gatewayd.

		virtual /*int*/ ssize_t send (ACE_Message_Block *mb); //pt
		// Send an Peer event to gatewayd, using <nonblk_put>.

		virtual int nonblk_put (ACE_Message_Block *mb);
		// Perform a non-blocking <put>, which tries to send an event to the
		// gatewayd, but only if it isn't flow controlled.

		int subscribe (void);
		// Register Consumer subscriptions with the gateway.

		// = Event/state/action handlers.

		int await_events (void);
		// Action that receives events.

		int db_query (void);

		ACE_Message_Block *consolidate(ACE_Message_Block *event);

		//.......................................................
		int application_id_;
		// Samson Application ID of the peer, which is obtained from the gatewayd.

		// Used in recv method
		ACE_Message_Block *data_frag_;
		SamsonHeader *header_frag_;
		int header_recvd_;

		size_t total_bytes_;
		// The total number of bytes sent/received to the gatewayd thus far.

		SharedAppMgr *samson_app_;
		// The Samson Application that will process this

		ACE_Recursive_Thread_Mutex mutex_;
		// Protect for multi-threading

		bool debug_;
		// set via transmit...for one message
};

} // namespace

#endif /* PEER_H */
