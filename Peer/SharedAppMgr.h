/* -*- C++ -*- */

/**
 *	@class SharedAppMgr
 *
 *	@ingroup SamsonPeer
 *
 *	@brief Samson Application Manager
 *
 *	This object is used to ...
 *
 *
 *	@note Attempts at zen rarely work.
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>, (C) 2006
 *
 */

#ifndef SharedAppMgr_H
#define SharedAppMgr_H

#include "ISE.h"

//#include <boost/circular_buffer.hpp>
#include <list>
#include <string>
#include <queue>

#include "ace/ACE.h"
#include "ace/DLL.h"
#include "ace/DLL_Manager.h"
#include "ace/Auto_Ptr.h"
#include "ace/Message_Block.h"
#include "ace/Map_Manager.h"
#include "ace/Synch.h"
#include "ace/High_Res_Timer.h"


#include "AppBase.h"
#include "SamsonHeader.h"
#include "SamsonEvent.h"


namespace Samson_Peer {

// Forward Declarations
class Peer_Handler;
class MessageBase;

// ===========================================================================
class ISE_Export SharedAppMgr
{
	// = TITLE
	//    Define a generic SharedAppMgr.
	//
	// = DESCRIPTION
	//

	public:

		static SharedAppMgr *instance (void);
		// Return Singleton.

		virtual ~SharedAppMgr ();
		// Perform termination

		int init (Peer_Handler *peer, AppBase *eap, int argc, ACE_TCHAR *argv[]);
		// Perform Application initialization.

		void handler_set (Peer_Handler *peer);
		// Allow this to be set later, not sure I like this

		int handle_event ( ACE_Message_Block *mb, const SamsonHeader *sh);
		// Process an incoming message from Peer_Handler

		int close (void);
		// The Application is finished, close down.

		int registerProcess (int appMsgID, MessageBase *msgHandler );
		int unregisterProcess (int appMsgID );
		// Allow the handle_event to dispatch the proper event

		SamsonPeerData * getRunPeerList(int &cnt);
		// Get the peerlist (used my a manager)

		// ---- Internal Debug Stuff ----
		void print_map(void);
		void print_map_all(void);
		void print_map_entry (int msg_id);

		boost::shared_ptr<std::stringstream> print_recv_list(void);
		boost::shared_ptr<std::stringstream> print_send_list(void);

		AppBase *SamApp() { return this->app_; }
		//  return a ptr to the Samson Application

		int sendCtrlMsg (int type, unsigned short flag=0x0);
		// Send a special Control message (used by MessageBase)

		int sendCmdMsg (const std::string &msg);
		// Send a Dispatcher Command (used by MessageBase)

		int publish(const std::string &msg, SamsonHeader *sh);
		int publish(ACE_Message_Block *data_mb, SamsonHeader *sh);
		// Low level rourtines to send a message (used by MessageBase)

		int sendMsg (int type, const std::string &str_msg , int flag, int id);
		// send a Samson Message

		int sendMsgOnCID (int cid, const char  *msg, unsigned int len);
		// send a message to a given connection id

	protected:

		int handoff_event (ACE_Message_Block *mb, const SamsonHeader *sh);
		// actually calls the shard app's message processor


		SharedAppMgr ();
		// Perform Application construction, protected ensures singleton.

		static SharedAppMgr *instance_;
		// Singleton.

		// Elapsed time the module is loaded
		ACE_High_Res_Timer app_timer_;

		enum { active, inactive } State;

		// The ACE Handeler who will be used to send our events.
		Peer_Handler *peer_;

		// = Build a "Map" to store the Simulation Routes in.
		typedef ACE_Map_Manager<int, MessageBase *, ACE_Null_Mutex> ProcessMap;
		typedef ACE_Map_Iterator<int, MessageBase *, ACE_Null_Mutex> ProcessMapIterator;
		typedef ACE_Map_Entry<int, MessageBase *> ProcessMapEntry;

		// this is were the messages are mapped to the calls in the loaded model
		ProcessMap map_;

		// this is the model loaded (only one at this juncture)
		AppBase *app_;

		// send and recieve logs
		//boost::circular_buffer<SamsonHeader> send_cb_(25);
		//boost::circular_buffer<SamsonHeader> recv_cb_(25);
		std::list<SamsonHeader> send_cb_;
		std::list<SamsonHeader> recv_cb_;


		// priority queue for framing
		std::priority_queue<SamsonEvent> q_;
};

typedef SharedAppMgr SAMSON_APPMGR;

} // namespace

#endif /* SharedAppMgr_H */
