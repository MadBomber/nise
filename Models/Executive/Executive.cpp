////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Executive.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Ben Atakora
//
//
// Company Name:     Lockheed Martin
//                   Missiles & Fire Control
//                   Dallas, TX
//
// Revision History:
//
// <yyyymmdd> <Eng> <Description of modification>
//
////////////////////////////////////////////////////////////////////////////////


#define ISE_BUILD_DLL

#include "Executive.hpp"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"

// used to get the command line
#include "ace/Get_Opt.h"

int Executive::init (int argc, ACE_TCHAR *argv[])
{
	// Receive the End of Engagement Message
	MessageFunctor<Executive>engagefunctor(this,&Executive::RecEngagement);
	mEndEngage->subscribe(&engagefunctor,0);

	//ACE_UNUSED_ARG(argc);
	//ACE_UNUSED_ARG(argv);

	ACE_Get_Opt get_opt (argc, argv, ACE_TEXT ("n:"));

	// pull the number of models to control from the command line
	for (int c; (argc != 0) && ((c = get_opt ()) != -1); )
	{
		switch (c)
		{
			case 'n':
				this->num_reps_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;
		}
	}
	ACE_DEBUG ((LM_DEBUG, "Total Number of Reps to run (%10d) Arg Count (%d)\n",this->num_reps_,argc));

	tgtmsl_count = 0;

	this->timing_.set(0);

	return this->SamsonModel::init(argc,argv);
}

int Executive::fini (void)
{
	return 1;
}


//.........................................................................................
//  Process End of Engagement Event
int Executive::RecEngagement(Samson_Peer::MessageBase *mb)
{
	 const SamsonHeader *sh = mb->get_header();

	++(this->tgtmsl_count);

	//if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG, " TargetModel::MonteCarlo_Step(%d:%d(%d):%d:%d) -> Received End Engagement at at t= %f\n",
			sh->run_id(),
			sh->message_id(),
			sh->app_msg_id(),
			sh->peer_id(),
			sh->unit_id(),
			this->currTime_
		));
	}


	// sends End of Run Event
	if(this->tgtmsl_count == this->num_reps_)
	{
		ACE_DEBUG ((LM_INFO, " TargetModel::MonteCarlo_Step -> sending End Case \n"));
		//this->sendEndCase();
	}
	return 0;
}

//...................................................................................................
int Executive::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	this->tgtmsl_count = 0;
	return 1;
}

ACE_FACTORY_DECLARE(ISE,Executive)
