/**
 *  @file TimedController.h
 *
 *	@class TimedController
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

#include "ISE.h"
#include "SamsonModel.h"
#include "PeerTable.h"
#include "DeltaTimeStats.h"

//  Main Event Queue
#include "Event_Queue.hpp"

//#include "ace/Service_Config.h"
//#include "ace/Service_Object.h"
#include "ace/High_Res_Timer.h"
#include "ace/Log_Msg.h"

#include <map>
#include <set>

namespace Samson_Peer { class MessageBase; }

// ====================================================================================================
class ISE_Export TimedController : public Samson_Peer::SamsonModel
{
	public:

		//  Coding Standard Note: I would like all derived AppBase Classes to rely on init and fini.
		TimedController(): SamsonModel(){}
		~TimedController() {}

		// direct calls from the base class
		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		friend ISE_Export ostream& operator<<(ostream& output, const TimedController& p);

		// base class message triggers down-call these
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { return 0; }
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 0; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }

		// triggers on these messages
		int doInitCaseComplete (Samson_Peer::MessageBase *mb);
		int doInitEvent (Samson_Peer::MessageBase *mb);
		int doEndCaseComplete (Samson_Peer::MessageBase *mb);
		int doEndRunComplete (Samson_Peer::MessageBase *mb);
		int doRegisterEndEngage (Samson_Peer::MessageBase *mb);
		int doEndEngagement (Samson_Peer::MessageBase *mb);

		virtual int startSimulation(void);

	protected:

		virtual int handle_timeout (const ACE_Time_Value &, const void *arg);

		int StartNewFrame(void);

		void schedule_start(int);
		int (TimedController::*timeout_action)(void);
		int status_action(void);

		// number of models attached to the controller
		int nmodels_;

		// current number of models that are doing frames
		int step_count_;

		// number of start of frames sent
		int frame_count_sent_;

		// holds the peers that are participating in this job
		Samson_Peer::PeerTable peer_table;

		// Step time
		int step_hz_;
		ACE_Time_Value step_time_;

		// Elapsed execution time
		ACE_High_Res_Timer exec_timer_;

		// timer to track start of frames
		ACE_High_Res_Timer frame_timer_;

		// Collect timer Stats
		DeltaTimeStats schedule_stats_;

		// timer id for canceling
		long my_timer_id_;

		// total number of steps we want to send out
		int number_of_steps_;

		bool endGame_;

		// What models have registered to send and end_engagement
		std::set<int> end_engagement_set_;

		void print();
};

ACE_FACTORY_DEFINE(ISE,TimedController)


#endif
