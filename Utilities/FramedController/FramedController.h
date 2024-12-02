/**
 *  @file FramedController.h
 *
 *	@class FramedController
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
class ISE_Export FramedController : public Samson_Peer::SamsonModel //, public ACE_Service_Object
{
	public:

		//  Coding Standard Note: I would like all derived AppBase Classes to rely on init and fini.
		FramedController();
		~FramedController() {}

		// direct calls from the base class
		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		friend ISE_Export ostream& operator<<(ostream& output, const FramedController& p);

		// base class message triggers down-call these
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *); // { return 1; }
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { return 0; }
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }

		// triggers on these messages
		int doInitCaseComplete (Samson_Peer::MessageBase *mb);
		int doInitEvent (Samson_Peer::MessageBase *mb);
		int doEndFrame (Samson_Peer::MessageBase *mb);
		int doEndCaseComplete (Samson_Peer::MessageBase *mb);
		int doEndRunComplete (Samson_Peer::MessageBase *mb);
		int doTimeAdvanced (Samson_Peer::MessageBase *mb);
		int doRegisterEndEngage (Samson_Peer::MessageBase *mb);
		int doEndEngagement (Samson_Peer::MessageBase *mb);
		int doPauseSimulation (Samson_Peer::MessageBase *mb);
		int doStartSimulation (Samson_Peer::MessageBase *mb);


	protected:

		enum Timer
		{
			STARTUP,
			WATCHDOG,
			FRAME
		};

		virtual int handle_timeout (const ACE_Time_Value &, const void *arg);

		void AdvanceTime(void);
		void StartNewFrame(void);

		void schedule_start(int);

		// int (FramedController::*timeout_action)(void);
		int watchdog_action(void);
		int startsim_action(void);



		void print();

		// holds the peers that are participating in this job
		Samson_Peer::PeerTable peer_table;

		// What models have registered to send and end_engagement
		std::set<int> end_engagement_set_;

		// timer to track start of frames
		ACE_High_Res_Timer delta_frame_timer_;
		ACE_High_Res_Timer delta_frame_timeout_;

		// startup timer
		int start_timer_;

		// watchdog timer
		int watchdog_timer_;

		// frame timer
		int frame_timer_;

		// number of models attached to the controller
		int nmodels_;

		// current number of models that are doing frames
		int step_count_;

		// number of start of frames sent
		int frame_count_sent_;

		// total number of cases to run
		int MonteCarlo_Number_Of_Runs_;

		// if we are in endgame state
		bool endGame_;

		// Rondevous
		int start_frame_hz_;

		bool missed_timeout_;
		bool ready_to_start_frame_;

		// Stop the controller before the next StartFrame message
		bool paused_;

		// last frame to process, stop the job
		unsigned int max_frame_;

};

ACE_FACTORY_DEFINE(ISE,FramedController)


#endif
