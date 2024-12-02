////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Toc.cpp
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

#include "Toc.hpp"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"
#include <cmath>

//...............................................................................
//...............................................................................
int TOC::init (int argc, ACE_TCHAR *argv[])
{
	// Setup Messages
	mTgtSrvMeasured = new SrMeasuredTargetStates();   // receive
	MessageFunctor<TOC>srinputfunctor(this,&TOC::processSrInput);
	mTgtSrvMeasured->subscribe(&srinputfunctor,0);

	mTgtTrkMeasured = new TrkRadarMeasuredTargetStates();   // receive
	MessageFunctor<TOC>mfrcinputfunctor(this,&TOC::processTrkRadarInputToc);
	mTgtTrkMeasured->subscribe(&mfrcinputfunctor,0);

	mRadarOn = new TrkRadarOnCmd ();  // send
	mLaunchRequest = new LaunchRequest ();  // send
	mTocEndEngage = new TargetDestroyed (); // send

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int TOC::fini (void)
{
	delete mTgtSrvMeasured;
	delete mTgtTrkMeasured;
	delete mRadarOn;
	delete mLaunchRequest;
	delete mTocEndEngage;
	return 1;
}

//...................................................................................................
int TOC::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	tocState = 0x0;
	mfcrRange = 25000.0;
	mfcrOnTime = -999.0;

	for (int i=0; i<3; ++i)
	{
		mfcrOn[i] = false;
		launch[i] = false;
		tgtdest[i] = false;
	}

	launchRange = 17340.0;
	//range = -999.0;

	return 1;

}


//...................................................................................................
int TOC::processSrInput (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int tgtUnitID = mTgtSrvMeasured->unitID_;
	int ndx = tgtUnitID-1;

	double range;
	SamsonMath::Vec3<double> position;

	tocState |= 0x0001;

	//SrInput->print();
	position = mTgtSrvMeasured->position_;
	range = sqrt(position.getX()*position.getX() +position.getY()*position.getY());
	// interesting, range is downrange from the origin


	if ((range <= mfcrRange) && !mfcrOn[ndx])
	{
		mfcrOnTime = 0.0;
		mfcrOn[ndx] = true;
		mRadarOn->time_   = currTime_;
		mRadarOn->on_     = mfcrOn[ndx];
		mRadarOn->unitID_ = tgtUnitID;
		mRadarOn->publish(this->currFrame_, this->send_count_++);

		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
		{
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) TOC::processSrInput( Job:%d Msg:%d(%d) Mdl:%d.%d) -> Turning Track Radar On at t= %f for Target %d  \n",
				sh->run_id(),
				sh->message_id(),
				sh->app_msg_id(),
				sh->peer_id(),
				sh->unit_id(),
				this->currTime_,
				tgtUnitID
				));
		}
	}

	return 1;
}

//...................................................................................................
int TOC::processTrkRadarInputToc (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int tgtUnitID = mTgtTrkMeasured->unitID_;
	int ndx = tgtUnitID-1;
	tocState |= 0x0002;

	SamsonMath::Vec3<double> position;
	double range, positionX;


	position = mTgtTrkMeasured->position_;
	range = position.getX();
	positionX = position.getX();
	if (range <= launchRange && !launch[ndx])
	{
		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
		{
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) TOC::processTrkRadarInputToc (Job:%d Msg:%d(%d) Mdl:%d.%d) -> Launching Missile at t= %f for Target %d  \n",
				sh->run_id(),
				sh->message_id(),
				sh->app_msg_id(),
				sh->peer_id(),
				sh->unit_id(),
				this->currTime_,
				tgtUnitID
				));
		}

		this->launch[ndx] = true;
		double launchTime = currTime_ + this->timing_.rate();
		mLaunchRequest->time_    = launchTime;
		mLaunchRequest->unitID_  = tgtUnitID;
		mLaunchRequest->publish(this->currFrame_, this->send_count_++, tgtUnitID);
	}

	//TODO better way is when Target position is equal to Missile position
	if (positionX <= 13346.67 && launch[ndx] && !tgtdest[ndx])
	{
		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
		{
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) TOC::processTrkRadarInputToc (Job:%d Msg:%d(%d) Mdl:%d.%d) -> Target Destroyed at t= %f for Target %d  \n",
				sh->run_id(),
				sh->message_id(),
				sh->app_msg_id(),
				sh->peer_id(),
				sh->unit_id(),
				this->currTime_,
				tgtUnitID
				));
		}

		tgtdest[ndx] = true;
		mTocEndEngage->time_   = currTime_;
		mTocEndEngage->state_  = tgtdest[ndx];
		mTocEndEngage->unitID_ = tgtUnitID;
		mTocEndEngage->publish(this->currFrame_, this->send_count_++, tgtUnitID);
	}

	return 1; // endFrame ();
}

ACE_FACTORY_DECLARE(ISE,Toc)
