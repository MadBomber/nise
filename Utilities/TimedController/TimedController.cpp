/**
 *	@file TimedController.cpp
 *
 *	@class TimedController
 *
 *	@brief This controls execution of "Frame" models  on a timeclock step
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#define ISE_BUILD_DLL

#include "ISERelease.h"
#include "ISETrace.h" // first to toggle tracing


#include "TimedController.h"
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
// ........................................................................................
// ........................................................................................
// ........................................................................................
int TimedController::init(int argc, ACE_TCHAR *argv[])
{
	ACE_TRACE("TimedController::init");

	// Track time from init() to fini()
	this->exec_timer_.start ();

	/*
	 * These messages all declared in the AppBase class.
	 * The controller is the place where the "end" and "completed" messages need be processed
	 */

	// Receive Init Event Message (genearated by a hello event sent to dispatcher)
	MessageFunctor<TimedController>initfunctor(this,&TimedController::doInitEvent);
	mInitEvent->subscribe(&initfunctor,0);

	// Received Init Case Complete Message
	MessageFunctor<TimedController>iccmpfunctor(this,&TimedController::doInitCaseComplete);
	mInitCaseCmp->subscribe(&iccmpfunctor,0);

	// Receive End of a Case Completed Monte Carlo Message
	MessageFunctor<TimedController>endcasecmpfunctor(this,&TimedController::doEndCaseComplete);
	mEndCaseCmp->subscribe(&endcasecmpfunctor,0);

	// Receive End the Run Completed Message
	MessageFunctor<TimedController>endruncmpfunctor(this,&TimedController::doEndRunComplete);
	mEndRunCmp->subscribe(&endruncmpfunctor,0);

	// Receive Register to receive End of Engagement Message
	MessageFunctor<TimedController>registerEndEngageFunctor(this,&TimedController::doRegisterEndEngage);
	mRegisterEndEngage->subscribe(&registerEndEngageFunctor,0);

	// Receive End of Engagement Message
	MessageFunctor<TimedController>endEngageFunctor(this,&TimedController::doEndEngagement);
	mEndEngage->subscribe(&endEngageFunctor,0);

	// crude counting hack till we have a real event queueing system
	this->step_count_ = 0;
	this->frame_count_sent_ = 0;

	// used to cance the periodic timer
	this->my_timer_id_ = 0;

	// Fill the PeerTable
	this->nmodels_ = Samson_Peer::SAMSON_OBJMGR::instance ()->getPeerTable (run_id_,peer_table);

	// Become the Job Master
	Samson_Peer::SAMSON_OBJMGR::instance ()->setRunMaster ();

	// pull the number of models to control from the command line
	ACE_Get_Opt get_opt (argc, argv, ACE_TEXT ("m:f:"));
	for (int c; (argc != 0) && ((c = get_opt ()) != -1); )
	{
		switch (c)
		{
			case 'm':
				this->number_of_steps_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;

			case 'f':
				this->step_hz_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;
		}
	}

	// We are NOT going to do separate advance time and start frame messages
	this->StartFrameOnly();
	this->NoEndFrameResponse();

	this->timing_.set(0);  // don't step me
	this->schedule_start(3);  // wait 3 seconds for all the systems to report

	this->print();  // print what is supposed to be running

	return this->SamsonModel::init(argc,argv);
}


//........................................................................................
// Schedule a timer to wait for the start
void TimedController::schedule_start(int ntime)
{
	ACE_Time_Value const next_time (ntime);
	this->timeout_action = &TimedController::startSimulation;

	if (ACE_Reactor::instance ()->schedule_timer (this, 0, next_time) == -1)
		ACE_ERROR ((LM_ERROR, ACE_TEXT ("(%P|%t) %p\n"), ACE_TEXT ("schedule_timer")));
	else
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::schedule_start(%d)\n",ntime));
}

//...................................................................................................
int TimedController::info (ACE_TCHAR **info_string, size_t length) const
{
	ACE_TRACE("TimedController::info");
	std::stringstream myinfo;
	myinfo << *this;

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}


//...................................................................................................
ostream& operator<<(ostream& output, const TimedController& p)
{
    output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

    output << "TimedController:: "
    	<< " NModels: " << p.nmodels_
      	<< " NFC: " << p.step_count_
      	<< " NFCSent: " << p.frame_count_sent_
      	<< " NSTEP: " << p.number_of_steps_
      	<< " HZ: " << p.step_hz_
      	<< " EndGame: " << (p.endGame_?"true":"false")
    	<< p.peer_table
     	;

    return output;
}

//........................................................................................
// verifies all the models have checked in.
int TimedController::startSimulation(void)
{
	ACE_TRACE("TimedController::startSimulation");

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

//.........................................................................................
//  this steps the models on a "hard time" boundry by sending a "StartFrame" message
int TimedController::StartNewFrame(void)
{
	ACE_TRACE("TimedController::StartNewFrame");

	static bool sent_endCase = false;

	// Collect timing
	ACE_hrtime_t measured;
	this->frame_timer_.stop ();
	this->frame_timer_.elapsed_microseconds (measured);
	this->schedule_stats_.sample (measured*1.0e-6);

	if ( this->frame_count_sent_ >= this->number_of_steps_  && this->frame_count_sent_ != 0 )
	{
		if (!sent_endCase )
		{
			ACE_DEBUG ((LM_INFO,"(%P|%t) TimedController::StartNewFrame -> stopping run!"));
			this->sendEndCase();
			sent_endCase = true;
		}
	}
	else if ( !this->endGame_ )
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::StartNewFrame( %d of %d) (%f)\n",this->frame_count_sent_, this->number_of_steps_, measured*1.0e-6));

		this->currTime_ += 1.0/this->step_hz_;

		// advance the frame counter!!!!
		this->currFrame_++;

		this->frame_count_++;
		this->sendStartFrame (0);
		this->frame_count_sent_++;
		this->frame_timer_.start ();
	}
	return 1;
}

//........................................................................................
int TimedController::fini(void)
{
	ACE_TRACE("TimedController::fini");

	// stop timer and print execution time
	this->exec_timer_.stop ();
	ACE_hrtime_t measured;
	this->exec_timer_.elapsed_microseconds (measured);
	double interval_sec = measured * 1.0e-6;
	ACE_DEBUG((LM_DEBUG,"Execution time %f sec\n", interval_sec));

	//  Print scheduling measurements
	this->schedule_stats_.print();

	if ( this->my_timer_id_ > 0 ) ACE_Reactor::instance ()->cancel_timer (this->my_timer_id_);

	this->peer_table.empty();
	return 0;
}

//........................................................................................
int
TimedController::handle_timeout (const ACE_Time_Value &,
                               const void *)
{
	ACE_TRACE("TimedController::handle_timeout");

	(this->*timeout_action)();

	// Must return a zero to continue
	return 0;
}


//........................................................................................
//  Object Message:  mInitEvent
//  this is going to be the "register event"  ???
int TimedController::doInitEvent(Samson_Peer::MessageBase *)
{
	ACE_TRACE("TimedController::doInitEvent");
	return 1;
}

//.........................................................................................
// Object MessagemInitCaseCmp
int TimedController::doInitCaseComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doInitCaseComplete");
	const SamsonHeader *sh = mb->get_header();

	// count the number of InitFrame messages
	static int message_cnt = 0;

	//  Increment the number of times I am called.
	++message_cnt;

	if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::doInitCaseComplete (Job %d Msg %d(%d) Mdl %d Unit %d) -> Count=%d of %d \n",
			sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id(),
			message_cnt, this->nmodels_));
	}


	//  When all models have done the Initialization, then start sending frames
	//  THIS IS IMPORTANT CODE, it messages at this point are now model-to-model
	//  They will be assembled back to gether at doEndCaseComplete
	if(message_cnt == this->nmodels_)
	{

		// set the action
		this->timeout_action = &TimedController::StartNewFrame;

		// Set the stepping time
		this->step_time_.set (1.0/this->step_hz_);

		// schedule it periodically
		if ( ( this->my_timer_id_  = ACE_Reactor::instance ()->schedule_timer (this, 0, this->step_time_, this->step_time_)) == -1)
			ACE_ERROR ((LM_ERROR, ACE_TEXT ("(%P|%t) %p\n"), ACE_TEXT ("schedule_timer")));
		else
			ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::recurring(%d.%d)\n",
					this->step_time_.sec(),this->step_time_.usec() ));

		endGame_ = false;
		message_cnt = 0;

		this->frame_timer_.start ();
	}
	return 1;
}



//.........................................................................................
// Object Message: mInitCaseCmp
int TimedController::doEndCaseComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("FramedController::doEndCaseComplete");
	const SamsonHeader *sh = mb->get_header();

	// count the number of ______ messages
	static int message_cnt = 0;

	//  Increment the number of times I am called.
	++message_cnt;

	// Note:  this-nmodels represents the number of models have a non-zero rate
	if( message_cnt == this->step_count_)
	{
		endGame_ = false;
		message_cnt = 0;

		if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
		{
			ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndCaseComplete (Job:%d Msg:%d(%d) Mdl:%d-%d) -> sent\n",
				sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id()
				));
		}

		// Not Monte-Carlo capable
		this->sendEndRun();
	}
	else if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) FramedController::doEndCaseComplete(Job:%d Msg:%d(%d) Mdl:%d-%d) -> (%d of %d)\n",
			sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id(),
			message_cnt, this->step_count_));
	}
	return 1;

}

//.........................................................................................
// the object is mEndRunCmp

int TimedController::doEndRunComplete(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("TimedController::doEndRunComplete");

	const SamsonHeader *sh = mb->get_header();
	//if (DebugFlag::instance ()->enabled (DebugFlag::APB_DEBUG))
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::doEndRunComplete Model (Job:%d Msg:%d(%d) Mdl:%d-%d)\n",
			sh->run_id(), sh->message_id(), sh->app_msg_id(), sh->peer_id(), sh->unit_id()
		));
	}

	this->endGame_ = true;

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
				ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::doEndRunComplete - shutting down all the models"));
				this->stopSimulation();
		}
	}


	return 1;

}

//........................................................................................
//  Object Message:  mInitEvent
//  this is going to be the "register event"  ???
int TimedController::doRegisterEndEngage(Samson_Peer::MessageBase *mb)
{
	ACE_TRACE("TimedController::doRegisterEndEngage");

	const SamsonHeader *sh = mb->get_header();

	this->end_engagement_set_.insert(sh->peer_id());

	if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG) )
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::doRegisterEndEngage by %d, size now \n",
			sh->peer_id(), this->end_engagement_set_.size()));
	}

	return 1;
}

//.........................................................................................
//  Process End of Engagement Event
int TimedController::doEndEngagement(Samson_Peer::MessageBase *mb)
{
	 const SamsonHeader *sh = mb->get_header();

	 this->end_engagement_set_.erase(sh->peer_id());

	//if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::APB_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) TimedController::doEndEngagement(%d:%d(%d):%d:%d) -> Received End Engagement at at t= %f  Size(%d)\n",
			sh->run_id(),
			sh->message_id(),
			sh->app_msg_id(),
			sh->peer_id(),
			sh->unit_id(),
			this->currTime_,
			this->end_engagement_set_.size()
		));
	}

	// sends End of Run Event
	if(this->end_engagement_set_.empty())
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) TimedController::doEndEngagement -> sending End Case \n"));
		this->sendEndCase();
	}
	return 1;
}


// =====================================================================
void
TimedController::print()
{
	ACE_DEBUG ((LM_INFO,
		"(%P|%t) TimedController::print"
		"\n-------------------------------------------------------------"
		"\nTotal Number of Models = %d"
		"\nTotal Number of Models requiring stepping = %d"
		"\nStepping Frequency = %d"
		"\nMax number of Steps = %d"
		"\n-------------------------------------------------------------\n",
			this->nmodels_, this->step_count_, this->step_hz_, this->number_of_steps_));
	this->peer_table.print();
}

ACE_FACTORY_DECLARE(ISE,TimedController)
