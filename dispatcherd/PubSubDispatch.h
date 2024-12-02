/**
 *	@file PubSubDispatch.h
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef SAMSONDISPATCH_H
#define SAMSONDISPATCH_H

#include "ISE.h"

#include "DispatcherConfig.h"
#include "ConnectionHandler.h"
#include "SamsonHeader.h"
#include "ModelIdentity.h"
#include "SamsonTrace.h"

#include <string>
#include <sstream>

//....boost smart pointer
#include <boost/shared_ptr.hpp>

//....boost serialization
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"

#include "ace/Singleton.h"
#include "ace/Map_Manager.h"
#include "ace/Synch.h"
#include "ace/Synch_Traits.h"
#include "ace/Thread_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

#include "my_xml_oarchive.h"

namespace Samson_Peer {


// ===========================================================================
/**
	@author Jack Lavender <jack.lavender@lmco.com>
*/
class ISE_Export PubSubDispatch
{
	public:
		PubSubDispatch();
		~PubSubDispatch();

		// Initialize the Application Singleton
		int initialize(void);

		// Called to process a recvd msg
		int process(ConnectionHandler *rh, ACE_Message_Block *event, SamsonHeader *sh);

		int send_hello (ConnectionHandler *ch);

		const std::string attached_model_report (void);
		const std::string message_report (ConnectionHandler *rh);

	protected:

		void route_to_subscriber (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh);
		void route_to_master (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh);
		void route_to_peer (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh);
		void route_to_connection (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh);
		void route_to_job (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh);

		// TODO  Consolodate the Samson message sending stuff
		int send_ctrl_event (ConnectionHandler *ch, int type, bool master_only=false);

		// Process the hello exchange
		void process_hello_event (ConnectionHandler *rh, const SamsonHeader *sh);

		SamsonTrace msg_trace_;

		ACE_Recursive_Thread_Mutex mutex_;
		// TODO:  document this
};

#if defined (__ACE_INLINE__)
#include "PubSubDispatch.inl"
#endif /* __ACE_INLINE__ */

// =======================================================================
// Create a Singleton for the Application
// Manage this from EventChannel::destroy
typedef ACE_Unmanaged_Singleton<PubSubDispatch, ACE_Recursive_Thread_Mutex> PUBSUB_DISPATCH;

} // namespace

#endif
