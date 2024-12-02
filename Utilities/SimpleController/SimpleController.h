/**
 *  @file SimpleController.h
 *
 *	@class SimpleController
 *
 *	@brief This controller a "Framed Model" execution.
 *
 * There will be one of these for every job that is run with
 * a "Samson Model" (ref: samson_model.h)  This controls execution
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include "ISEExport.h"
#include "SamsonModel.h"
#include "PeerTable.h"

//  Main Event Queue
#include "Event_Queue.hpp"

//#include "ace/Service_Config.h"
//#include "ace/Service_Object.h"
#include "ace/Log_Msg.h"

#include <map>
#include <set>


namespace Samson_Peer { class MessageBase; }

// ====================================================================================================
class ISE_Export SimpleController : public Samson_Peer::SamsonModel
{
	public:

		//  Coding Standard Note: I would like all derived AppBase Classes to rely on init and fini.
		SimpleController();
		~SimpleController() {}

		// direct calls from the base class
		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		friend ISE_Export ostream& operator<<(ostream& output, const SimpleController& p);

		// base class message triggers down-call these
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *) { return 0; }
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }

		// triggers on these messages
		int doInitEvent (Samson_Peer::MessageBase *mb);
		int doEndEngagement (Samson_Peer::MessageBase *mb);
		int doEndRunComplete (Samson_Peer::MessageBase *mb);

	protected:

		enum Timer
		{
			STARTUP,
			WATCHDOG
		};

		virtual int handle_timeout (const ACE_Time_Value &, const void *arg);

		void schedule_start(int);

		// int (SimpleController::*timeout_action)(void);
		int startsim_action(void);

		// print status info
		void print();

		// holds the peers that are participating in this job
		Samson_Peer::PeerTable peer_table;

		// startup timer
		int start_timer_;

		// number of models attached to the controller
		int nmodels_;

		// if we are in endgame state
		bool endGame_;
};

ACE_FACTORY_DEFINE(ISE,SimpleController)


#endif
