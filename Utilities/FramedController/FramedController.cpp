/**
 *	@file FramedController.cpp
 *
 *	@class FramedController
 *
 *	@brief This controls execution of "Framed" models
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#define ISE_BUILD_DLL

#include "ISERelease.h"
#include "ISETrace.h" // first to toggle tracing


#include "FramedController.h"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"
#include "SimMsgType.h"
#include "Options.h"

// used to get the command line
#include "ace/Get_Opt.h"

#include "Model_ObjMgr.h"


#include "ace/Reactor.h"

using namespace Samson_Peer;


// ........................................................................................
FramedController::FramedController(): SamsonModel(),
start_timer_(-1),
watchdog_timer_(-1),
frame_timer_(-1),
nmodels_(0),
step_count_(0),
frame_count_sent_(0),
MonteCarlo_Number_Of_Runs_(1),
endGame_(false),
start_frame_hz_(0),
missed_timeout_(false),
ready_to_start_frame_(false),
paused_(false),
max_frame_(0)
{
}



// ........................................................................................
// ........................................................................................
// ........................................................................................
int FramedController::init(int argc, ACE_TCHAR *argv[])
{
	ACE_TRACE("FramedController::init");

	/*
	 * These messages all declared in the AppBase class.
	 * The controller is the place where the "end" and "completed" messages need be processed
	 */

	// Receive Init Event Message (genearated by a hello event sent to dispatcher)
	MessageFunctor<FramedController>initfunctor(this,&FramedController::doInitEvent);
	mInitEvent->subscribe(&initfunctor,0);

	// Received Init Case Complete Message
	MessageFunctor<FramedController>iccmpfunctor(this,&FramedController::doInitCaseComplete);
	mInitCaseCmp->subscribe(&iccmpfunctor,0);

	// Receive End of Frame Message
	MessageFunctor<FramedController>endframefunctor(this,&FramedController::doEndFrame);
	mEndFrame->subscribe(&endframefunctor,0);

	// Receive End of a Case Completed Monte Carlo Message
	MessageFunctor<FramedController>endcasecmpfunctor(this,&FramedController::doEndCaseComplete);
	mEndCaseCmp->subscribe(&endcasecmpfunctor,0);

	// Receive End the Run Completed Message
	MessageFunctor<FramedController>endruncmpfunctor(this,&FramedController::doEndRunComplete);
	mEndRunCmp->subscribe(&endruncmpfunctor,0);

	// Receive Time Advanced Message
	MessageFunctor<FramedController>timeadvancedfunctor(this,&FramedController::doTimeAdvanced);
	mTimeAdvanced->subscribe(&timeadvancedfunctor,0);

	// Receive Register to receive End of Engagement Message
	MessageFunctor<FramedController>registerEndEngageFunctor(this,&FramedController::doRegisterEndEngage);
	mRegisterEndEngage->subscribe(&registerEndEngageFunctor,0);

	// Receive End of Engagement Message
	MessageFunctor<FramedController>endEngageFunctor(this,&FramedController::doEndEngagement);
	mEndEngage->subscribe(&endEngageFunctor,0);

	// Receive Pause Simulation Message
	MessageFunctor<FramedController>pauseSimFunctor(this,&FramedController::doPauseSimulation);
	mPauseSimulation->subscribe(&pauseSimFunctor,0);

	// Receive Start Simulation Message
	MessageFunctor<FramedController>startSimFunctor(this,&FramedController::doStartSimulation);
	mStartSimulation->subscribe(&startSimFunctor,0);



	// Fill the PeerTable
	this->nmodels_ = Samson_Peer::SAMSON_OBJMGR::instance ()->getPeerTable (run_id_,peer_table);

	// Become the Job Master
	Samson_Peer::SAMSON_OBJMGR::instance ()->setRunMaster ();


	// Process the command line
	ACE_Get_Opt get_opt (argc, argv, "j:k:l:");

	static const ACE_TCHAR* mc_runs = ACE_TEXT ("MC");
	static const ACE_TCHAR* adv_time = ACE_TEXT ("advance_time");
	static const ACE_TCHAR* start_frame_hz = ACE_TEXT ("start_frame_hz");
	static const ACE_TCHAR* max_frame = ACE_TEXT ("max_frame");

	get_opt.long_option (mc_runs, ACE_Get_Opt::ARG_REQUIRED);
	get_opt.long_option (adv_time, ACE_Get_Opt::NO_ARG);
	get_opt.long_option (start_frame_hz, ACE_Get_Opt::ARG_REQUIRED);
	get_opt.long_option (max_frame, ACE_Get_Opt::ARG_REQUIRED);


	int c;
	// pull the number of models to control from the command line
	while ((c = get_opt ()) != -1)
	{
		//ACE_DEBUG ((LM_ERROR, "(%P|%t) FramedTater::provision() -> argv %c - %d\n",c,c));
		switch (c)
		{
		case 0:
			if (ACE_OS::strcmp (get_opt.long_option (), mc_runs) == 0)
			{
				this->MonteCarlo_Number_Of_Runs_ = ACE_OS::atoi (get_opt.opt_arg ());
			}
			else if (ACE_OS::strcmp (get_opt.long_option (), adv_time) == 0)
			{
				this->separate_advance_time_ = true;
			}
			else if (ACE_OS::strcmp (get_opt.long_option (), start_frame_hz) == 0)
			{
				this->start_frame_hz_ = ACE_OS::atoi (get_opt.opt_arg ());
			}
			else if (ACE_OS::strcmp (get_opt.long_option (), max_frame) == 0)
			{
				this->max_frame_ = ACE_OS::atoi (get_opt.opt_arg ());
			}
			break;
			/*
             default:
                 ACE_DEBUG ((LM_ERROR, "(%P|%t) FramedTater::provision() -> unexpected command line arg %c\n",c));
			 */
		}
	}


	this->timing_.set(0);  // I do not react to time
	this->schedule_start(3); // wait this long to check for all the models ready

	this->print();

	return this->SamsonModel::init(argc,argv);
}

//........................................................................................
int FramedController::MonteCarlo_InitCase (Samson_Peer::MessageBase *)
{
	this->frame_count_sent_ = 0;
	this->currFrame_ = 0;
	return 1;
}

//........................................................................................
// Schedule a timer to wait for the start
void FramedController::schedule_start(int ntime)
{
	ACE_Time_Value const next_time (ntime);
	if ( (this->start_timer_ =  ACE_Reactor::instance ()->schedule_timer (this,  (const void *) FramedController::STARTUP, next_time)) == -1)
		ACE_ERROR ((LM_ERROR, ACE_TEXT ("(%P|%t) %p\n"), ACE_TEXT ("schedule_timer")));
	else
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::schedule_start(%d)\n",ntime));
		//this->print();
	}
}



//...................................................................................................
int FramedController::info (ACE_TCHAR **info_string, size_t length) const
{
	ACE_TRACE("FramedController::info");
	std::stringstream myinfo;
	myinfo << *this;

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}

//...................................................................................................
ostream& operator<<(ostream& output, const FramedController& p)
{
    output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

    output << "FramedController:: "
    	<< " NModels: " << p.nmodels_
      	<< " NFC: " << p.step_count_
      	<< " NFCSent: " << p.frame_count_sent_
      	<< " NMC: " << p.MonteCarlo_Number_Of_Runs_
      	<< " EndGame: " << (p.endGame_?"true":"false")
    	<< p.peer_table
     	;

    return output;
}

//........................................................................................
int FramedController::fini(void)
{
	ACE_TRACE("FramedController::fini");

	if ( this->start_timer_ > 0 ) ACE_Reactor::instance ()->cancel_timer (this->start_timer_);
	if ( this->watchdog_timer_ > 0 ) ACE_Reactor::instance ()->cancel_timer (this->watchdog_timer_);
	if ( this->frame_timer_ > 0 ) ACE_Reactor::instance ()->cancel_timer (this->frame_timer_);

	this->peer_table.empty();
	return 0;
}


//	=================================================================================================
//	=================================================================================================
//........................................................................................
int
FramedController::handle_timeout (const ACE_Time_Value &tv, const void *arg)
{
	ACE_TRACE("FramedController::handle_timeout");

	int time_tag = static_cast <int> (reinterpret_cast <size_t> (arg));
	ACE_UNUSED_ARG(tv);


	if ( time_tag ==  FramedController::STARTUP )
	{
		this->start_timer_ = -1;
		this->startsim_action();
	}
	else if ( time_tag ==  FramedController::WATCHDOG )
	{
		// this one's periodic, cancel it in fini!
		this->watchdog_action();
	}
	else if ( time_tag ==  FramedController::FRAME )
	{
		// this one's likely to be scheduled, cancel it in fini!

		// Collect timing
		ACE_hrtime_t measured;
		this->delta_frame_timeout_.stop ();
		this->delta_frame_timeout_.elapsed_microseconds (measured);

		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG) )
		{
			ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::handle_timeout Frame(%D) Frame:%d Time:%f delta:%f\n",this->currFrame_, this->currTime_, measured*1.0e-6));
		}

		if (!this->paused_ && this->ready_to_start_frame_)
		{
			if ( this->separate_advance_time_ )
				this->AdvanceTime ();
			else
				this->StartNewFrame();

			this->missed_timeout_ = false;
			this->ready_to_start_frame_= false;
		}
		else
			this->missed_timeout_ = true;


	}
	else
	{
		ACE_DEBUG ((LM_ERROR, "(%P|%t) FramedController::handle_timeout  ERROR no action (%d)\n",time_tag));
	}

	// Must return a zero to continue
	return 0;
}


//........................................................................................
//  Action from the "handle_timeout"
int FramedController::startsim_action(void)
{
	ACE_TRACE("FramedController::startsim_action");

	if ( !Samson_Peer::SAMSON_OBJMGR::instance ()->checkPeersStarted (peer_table) )
	{
		this->schedule_start(3);
	}
	else
	{
		this->step_count_ = Samson_Peer::SAMSON_OBJMGR::instance ()->getStepRate ();
		this->sendCtrlMsg (SimMsgType::LOG_EVENT_CHANNEL_STATUS, SimMsgFlag::job);;
		this->print ();
		// SamsonModel subscribes to this message (goes to all models in this job)
		this->sendInitCase ();
	}

	return 1;
}

//........................................................................................
//  Action from the "handle_timeout" after the models are running
int FramedController::watchdog_action(void)
{
	static int saved_frame_count = -1;
	static bool msg_sent = false;

	// check for stalled job
	if ( saved_frame_count == this->frame_count_sent_  && !endGame_  && !msg_sent)
	{
		ACE_DEBUG ((LM_DEBUG,"(%P|%t) FramedController::watchdog_action(%D) -> Job Stalled at %d\n",  this->frame_count_sent_ ));
		msg_sent = true;
		this->requestJobStatus();
		ACE_OS::sleep(3);
		this->stopSimulation();
	}
	else
		saved_frame_count = this->frame_count_sent_;


	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::watchdog_action(%D) -> saved frame count:(%d), frame count(%d)\n",
				saved_frame_count, this->frame_count_sent_));
	}

	return 1;
}



//	=================================================================================================
//	=================================================================================================
//........................................................................................
//  Object Message:  mInitEvent
//  this is going to be the "register event"  ???
int FramedController::doInitEvent(Samson_Peer::MessageBase *)
{
	ACE_TRACE("FramedController::doInitEvent");
	return 1;
}

//.........................................................................................
// Object MessagemInitCaseCmp
// The models have all responded to the InitCase message, so now onto Framing
int FramedController::doInitCaseComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doInitCaseComplete");

	// Set of messages we are waiting to respond to and InitCase message
	static std::set<int> init_case_set;

	// trap flag to initialize the set
	static bool initialized = false;


	if (!initialized)
	{
		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			init_case_set.insert(a->peer_id);
		}
		initialized = true;
	}


	const SamsonHeader *sh = mb->get_header();

	init_case_set.erase(sh->peer_id());

	if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) FramedController::doInitCaseComplete(%D) -> Size:%d\n", init_case_set.size()));
		sh->print();
	}

	// starts the framing!
	if(init_case_set.empty())
	{
		//ACE_Time_Value const recur_time (Samson_Peer::Options::instance ()->stall_timeout ());  // seconds
		ACE_Time_Value const recur_time (3600.0);  // seconds
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) FramedController::doInitCaseComplete(%D) -> Stall:%f secs\n", (recur_time.msec()/1000.0) ));
		if ( (this->watchdog_timer_ = ACE_Reactor::instance ()->schedule_timer (this,  (const void *) FramedController::WATCHDOG, recur_time, recur_time)) == -1)
			ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "schedule_timer"));

		endGame_ = false;
		initialized = false;

		// if we made it here, send out the start frame
		if ( this->separate_advance_time_ )
			this->AdvanceTime ();
		else
			this->StartNewFrame();

	}


	return 1;
}

//.........................................................................................
// Object Message:  mEndFrame
int FramedController::doEndFrame(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doEndFrame");
	const SamsonHeader *sh = mb->get_header();

	if(endGame_ == false)
	{
		static std::set<int> endframe_set;

		// trap flag to initialize the set
		static bool initialized = false;


		if (!initialized)
		{
			PeerTable::PeerMapIterator iter;
			for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
			{
				PeerRecord *a = iter->second;
				if ( a->rate != 0 ) endframe_set.insert(a->peer_id);
			}
			initialized = true;
		}

		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			if ( a->peer_id == sh->peer_id () )
			{
				a->waiting_on_endframe = false;
			}
		}

		endframe_set.erase(sh->peer_id());


		//if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
		{
			ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndFrame(%D) Size:%d -> ", endframe_set.size()));
			sh->print();
		}

		if(endframe_set.empty())
		{
			if ( this->frame_count_ == this->max_frame_ )
			{
				this->sendEndCase();
			}

			// if we made it here, send out the start frame
			else if ( !this->paused_ && (this->start_frame_hz_ == 0  ||  (this->start_frame_hz_ != 0 && this->missed_timeout_)) )
			{
				if ( this->separate_advance_time_ )
					this->AdvanceTime ();
				else
					this->StartNewFrame();

				this->ready_to_start_frame_ = false;
			}
			else
				this->ready_to_start_frame_ = true;

			initialized = false;
		}

	}

	return 1;
}





//.........................................................................................
// Object Message: mInitCaseCmp
int FramedController::doEndCaseComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doEndCaseComplete");

	const SamsonHeader *sh = mb->get_header();

	// Set of messages we are waiting to respond to and InitCase message
	static std::set<int> endcase_complete_set;

	// trap flag to initialize the set
	static bool initialized = false;


	if (!initialized)
	{
		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			endcase_complete_set.insert(a->peer_id);
		}
		initialized = true;
	}

	endcase_complete_set.erase(sh->peer_id());

	//if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndCaseComplete(%D) Size:%d -> ", endcase_complete_set.size() ));
		sh->print();
	}

	// Note:  this-nmodels represents the number of models have a non-zero rate
	if( endcase_complete_set.empty())
	{
		endGame_ = false;
		initialized = false;

		if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
		{
			ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndCaseComplete (%D) Sent:%s -> ",
				((caseNumber_ == MonteCarlo_Number_Of_Runs_) ? "End Run" : "End Case")));
			sh->print();
		}

		// Next case or end the run
		if (caseNumber_ >= MonteCarlo_Number_Of_Runs_)
		{
			this->sendEndRun();
		}
		else
		{
			++caseNumber_;
			this->sendInitCase();
		}
	}

	return 1;

}

//.........................................................................................
// ObjectMessage: mEndRunCmp
int FramedController::doEndRunComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doEndRunComplete");

	const SamsonHeader *sh = mb->get_header();
	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndRunComplete(%D) ->"));
		sh->print();
	}

	endGame_ = true;

	// process if not me!
	if (this->model_id_ != sh->peer_id () )
	{

		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			if ( a->peer_id == sh->peer_id () &&  !a->powered_down )
			{
				a->powered_down = true;
			}
#if 0
			else
			{
				ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndRunComplete (Job:%d Msg:%d(%d) Mdl:%d-%d) -> Model(%d) not found\n",
					sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id(),
					sh->peer_id()));
			}
#endif
		}

	}


	// Now to shut it all down, if all the others are all ready to be shutdown
	{
		bool shut_me_down = true;
		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			if ( a->peer_id != this->model_id_ &&  !a->powered_down )
			{
				shut_me_down = false;
				break;
			}
		}
		if ( shut_me_down )
		{
				ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndRunComplete - shutting down all the models\n"));
				this->stopSimulation();
		}
	}


	return 1;

}


//........................................................................................
//  Object Message:  mInitEvent
//  this is going to be the "register event"  ???
int FramedController::doRegisterEndEngage(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doRegisterEndEngage");

	const SamsonHeader *sh = mb->get_header();

	this->end_engagement_set_.insert(sh->peer_id());


	//ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doRegisterEndEngage %d\n", sh->peer_id()));
	//sh->print ();

	return 1;
}

//.........................................................................................
//  Process End of Engagement Event
int FramedController::doEndEngagement(Samson_Peer::MessageBase *mb)
{
	 const SamsonHeader *sh = mb->get_header();

	this->end_engagement_set_.erase(sh->peer_id());


	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndEngagement(%D) Size:%d-> ",this->end_engagement_set_.size()));
		sh->print();
	}

	// sends End of Run Event
	if(this->end_engagement_set_.empty())
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndEngagement(%D) -> sending End Case \n"));
		std::string verbose("verbose");
		this->sendDispatcherCommand(verbose);
		this->sendEndCase();
	}
	return 0;
}

//.........................................................................................
//  Process Pause Simulation Event
int FramedController::doPauseSimulation(Samson_Peer::MessageBase *mb)
{
	 const SamsonHeader *sh = mb->get_header();

	this->paused_ = true;


	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doPauseSimulation(%D) -> "));
		sh->print();
	}
	return 0;
}

//.........................................................................................
//  Process Start Simulation Event
int FramedController::doStartSimulation(Samson_Peer::MessageBase *mb)
{
	 const SamsonHeader *sh = mb->get_header();

	this->paused_ = false;
	if ( this->ready_to_start_frame_ )
	{
		if ( this->separate_advance_time_ )
			this->AdvanceTime ();
		else
			this->StartNewFrame();

		this->ready_to_start_frame_ = false;
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doStartSimulation(%D) -> "));
		sh->print();
	}
	return 0;
}


//.........................................................................................
// Object Message: mTimeAdvanced
// This is a control message, no data is used
int FramedController::doTimeAdvanced(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doEndFrame");
	const SamsonHeader *sh = mb->get_header();

	//int etype = sh->type();
	//unsigned int app_msg_id = sh->app_msg_id ();

	//if ( etype == SimMsgType::TIME_ADVANCED )
	//{

		PeerTable::PeerMapIterator iter;
		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			if ( a->peer_id == sh->peer_id () )
			{
				a->waiting_on_timeadvance = false;
			}
		}

		if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
		{
			ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doTimeAdvanced (Job:%d Msg:%d(%d) Mdl:%d.%d) -> for Model ID(%d)\n",
				sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id(), sh->peer_id()));
		}

		for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
		{
			PeerRecord *a = iter->second;
			if ( a->waiting_on_timeadvance == true )  return 1;  // at least one model has not advanced time
		}

		//this->peer_table.print();

		// if we made it here, sent out the start frame
		this->StartNewFrame ();
	//}

	return 1;
}

//.........................................................................................
// Sends  "AdvanceTime" message
void FramedController::AdvanceTime(void)
{
	ACE_TRACE("FramedController::AdvanceTime");

	// testing a delay for repeatability
	//ACE_Time_Value sval = ACE_Time_Value(0,500);
	//ACE_OS::sleep(sval);

	// advance the frame counter!!!!
	this->currFrame_++;

	// compute the current time
	this->currTime_ = this->currFrame_*this->timing_.rate();

	// build the queue
	PeerTable::PeerMapIterator iter;
	for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
	{
		PeerRecord *a = iter->second;
		if ( a->rate != 0 )
		{
			a->waiting_on_timeadvance = true;
		}
	}

	this->sendAdvanceTime ();

	{
		if ( this->start_frame_hz_ != 0)
		{
			ACE_Time_Value frame_time;
			frame_time.set(1.0/this->start_frame_hz_);
			if ( (this->frame_timer_ = ACE_Reactor::instance ()->schedule_timer (this,  (const void *) FramedController::FRAME, frame_time)) == -1)
				ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "schedule_timer"));
			this->delta_frame_timeout_.start ();
		}
		this->delta_frame_timer_.start ();
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::AdvanceTime(%D)\n"));
	}
}

//.........................................................................................
// Sends  "StartFrame" message
void FramedController::StartNewFrame(void)
{
	ACE_TRACE("FramedController::StartNewFrame");


	// Collect timing
	ACE_hrtime_t measured;
	this->delta_frame_timer_.stop ();
	this->delta_frame_timer_.elapsed_microseconds (measured);
	this->schedule_stats_.sample (measured*1.0e-6);


	volatile int icnt = 0;

	if ( !this->separate_advance_time_ )
	{
		this->currFrame_++;
		// compute the current time
		this->currTime_ = this->currFrame_*this->timing_.rate();

	}

	// debugging!
	this->frame_count_++;

	// build the queue
	PeerTable::PeerMapIterator iter;
	for (iter = peer_table.begin(); iter != peer_table.end(); iter++)
	{
		PeerRecord *a = iter->second;
		if ( a->rate != 0 )
		{
			a->waiting_on_endframe = true;
			//this->sendStartFrame (a->peer_id );
			icnt++;
		}
	}

	this->sendStartFrame (0);

	// book keep the number of frames sent
	this->frame_count_sent_++;

	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::StartNewFrame(%D) -> sent icnt:%d fc:%d fcs:%d t:%f hz:%d delta:%f\n",
			icnt, this->frame_count_, this->frame_count_sent_, this->currTime_, this->start_frame_hz_, measured*1.0e-6));
	}


	// Schedule a timer to coordinate the next StartFrame
	if ( !this->separate_advance_time_ )
	{
		if ( this->start_frame_hz_ != 0)
		{
			ACE_Time_Value frame_time;
			frame_time.set(1.0/this->start_frame_hz_);
			if ( (this->frame_timer_ = ACE_Reactor::instance ()->schedule_timer (this,  (const void *) FramedController::FRAME, frame_time)) == -1)
				ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "schedule_timer"));
			this->delta_frame_timeout_.start ();
		}
		this->delta_frame_timer_.start ();
	}
}

// =====================================================================
void
FramedController::print()
{
	ACE_DEBUG ((LM_INFO,
		"(%P|%t) FramedController::print"
		"\n-------------------------------------------------------------"
		"\nTotal Number of Models = %d"
		"\nTotal Number of Models requiring stepping = %d"
		"\nNumber of MC Runs = %d"
		"\nMax Frame = %d"
		"\n-------------------------------------------------------------\n",
			this->nmodels_, this->step_count_, this->MonteCarlo_Number_Of_Runs_, this->max_frame_));
	this->peer_table.print();
}

ACE_FACTORY_DECLARE(ISE,FramedController)
