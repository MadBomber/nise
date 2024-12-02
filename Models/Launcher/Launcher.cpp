////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Launcher.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Hector Bayona
//                   Nancy Anderson
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

#include "Launcher.hpp"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"



Launcher::Launcher() : SamsonModel(),
mLaunchRequest (new LaunchRequest()),
mLaunchCmd (new LaunchCmd())
{
	for (int i =0; i<3; ++i) missileLaunched[i] = false;
}


//...................................................................................................
int Launcher::init (int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	MessageFunctor<Launcher> launchfunctor (this,&Launcher::launchMissile);
	mLaunchRequest->subscribe(&launchfunctor,0);

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int Launcher::fini (void)
{
	return 1;
}

//...................................................................................................
int Launcher::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	for (int i =0; i<3; ++i) missileLaunched[i] = false;
	return 1;
}


int Launcher::launchMissile (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int mslUnitID = mLaunchRequest->unitID_;
	bool launch = true;
	double launchTime = mLaunchRequest->time_;

	if (launch && !missileLaunched[mslUnitID-1] )
	{
		//if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
		{
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) Launcher::launchMissile() at t= %f (%f:%d) for Target %d (%d) \n",
				mLaunchRequest->time_,
				this->currTime_,
				this->currFrame_,
				mLaunchRequest->unitID_,
				this->unit_id_
			));
			sh->print();
		}


		this->missileLaunched[mslUnitID-1] = true;
		mLaunchCmd->time_   = launchTime;
		mLaunchCmd->unitID_ = mslUnitID;
		mLaunchCmd->publish(this->currFrame_, this->send_count_++, mslUnitID);
		//ACE_DEBUG ((LM_DEBUG, "(%P|%t)Launcher::launchMissile -> UnitID:%d)\n",mslUnitID));

	}
	return 1;
}

int Launcher::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
	if ( this->save_state_ ) this->toDB("Launcher");
	return 1;
}

ACE_FACTORY_DECLARE(ISE,Launcher)
