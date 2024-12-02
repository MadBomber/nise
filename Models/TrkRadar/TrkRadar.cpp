////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Mfcr.cpp
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

#include "TrkRadar.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "time.h"

//...................................................................................................
TrkRadar::TrkRadar():
	SamsonModel(),
	mDownlink (new MyMissileDownlink()),
	mUplink (new TrkRadarUplink()),
	mTgtTruth (new TruthTargetStates()),
	mRadarOn (new TrkRadarOnCmd()),
	mLaunchCmd (new LaunchCmd()),
	TrkRadarToToc (new TrkRadarMeasuredTargetStates())
{
}

//...................................................................................................
int TrkRadar::init (int argc, ACE_TCHAR *argv[])
{
	MessageFunctor<TrkRadar>targetinput(this,&TrkRadar::doTrackTarget);
	mTgtTruth->subscribe(&targetinput,0);

	MessageFunctor<TrkRadar>mfcronfunctor(this,&TrkRadar::processTrkRadarOn);
	mRadarOn->subscribe(&mfcronfunctor,0);

	MessageFunctor<TrkRadar>downlink(this,&TrkRadar::processDownlink );
	mDownlink->subscribe(&downlink,0);

	MessageFunctor<TrkRadar>missile(this,&TrkRadar::missileAway );
	mLaunchCmd->subscribe(&missile,0);

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int TrkRadar::fini (void)
{
	return 1;
}

int TrkRadar::MonteCarlo_InitCase (Samson_Peer::MessageBase *)
{
	for ( int i=0; i<3; ++i)
	{
		launchMissile[i] = false;
		trkRadarOn[i] = false;
	}
	return 1;
}

int TrkRadar::processTrkRadarOn (Samson_Peer::MessageBase *)
{
	int ndx = mRadarOn->unitID_ -1;

	if ( ndx < 0 || ndx > 2)
	{
		// bad index, stall the run!
		return 0;
	}

	this->trkRadarOn[ndx] = mRadarOn->on_;
	this->timeStampRadarOn[ndx] = currTime_;
	this->timeStampRadarOn[mRadarOn->unitID_-1] = currTime_;
	return 1;
}

int TrkRadar::doTrackTarget (Samson_Peer::MessageBase *)
{
	SamsonMath::Vec3<double> position;
	position       = mTgtTruth->position_;
	int tgtUnitID  = mTgtTruth->unitID_;
	int ndx = tgtUnitID -1;

	if ( ndx < 0 || ndx > 2)
	{
		ACE_DEBUG ((LM_DEBUG, "TrkRadar::doTrackTarget -> bad index: %d",ndx));

		ACE_TCHAR *msg = 0;
		int len = this->info (&msg, 4096);
		//std::string my_send = std::string("\n") + this->print_send_list ().c_str ();
		//std::string my_recv = std::string("\n") + this->print_recv_list ().c_str ();
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event: status (%d)\n%s\n", len, msg));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_send.c_str ()));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_recv.c_str ()));
		ACE::strdelete(msg);

		return 1;
	}

	if (this->trkRadarOn[ndx] && (this->timeStampRadarOn[ndx] != currTime_))
	{
		TrkRadarToToc->time_     = currTime_;
		TrkRadarToToc->position_ = position;
		TrkRadarToToc->unitID_   = tgtUnitID;
		TrkRadarToToc->publish (this->currFrame_, this->send_count_++, tgtUnitID);
	}

	// NOTE:  we are assuming that Missile 1 engages Target 1

	if (this->launchMissile[ndx])
	{
		mUplink->time_     = currTime_;
		mUplink->position_ = position;
		mUplink->unitID_   = tgtUnitID;
		mUplink->publish (this->currFrame_, this->send_count_++, tgtUnitID);
	}

	return 1;
}


int TrkRadar::missileAway (Samson_Peer::MessageBase *)
{
	int ndx = mLaunchCmd->unitID_ -1;

	if ( ndx < 0 || ndx > 2)
	{
		ACE_DEBUG ((LM_DEBUG, "TrkRadar::missileAway -> bad index: %d",ndx));

		ACE_TCHAR *msg = 0;
		int len = this->info (&msg, 4096);
		//std::string my_send = std::string("\n") + this->print_send_list ().c_str ();
		//std::string my_recv = std::string("\n") + this->print_recv_list ().c_str ();
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event: status (%d)\n%s\n", len, msg));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_send.c_str ()));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_recv.c_str ()));
		ACE::strdelete(msg);

		return 1;
	}

	this->launchMissile[ndx] = true;
	return 1;
}

int TrkRadar::processDownlink  (Samson_Peer::MessageBase *)
{
	int ndx = mDownlink->unitID_ -1;

	if ( ndx < 0 || ndx > 2)
	{
		ACE_DEBUG ((LM_DEBUG, "TrkRadar::processDownlink -> bad index: %d",ndx));

		ACE_TCHAR *msg = 0;
		int len = this->info (&msg, 4096);
		//std::string my_send = std::string("\n") + this->print_send_list ().c_str ();
		//std::string my_recv = std::string("\n") + this->print_recv_list ().c_str ();
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event: status (%d)\n%s\n", len, msg));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_send.c_str ()));
		//ACE_DEBUG ((LM_DEBUG, "%s\n", my_recv.c_str ()));
		ACE::strdelete(msg);

		return 1;
	}

	this->missilePosition[ndx] = mDownlink->position_;
	return 1;
}

ACE_FACTORY_DECLARE(ISE,TrkRadar)
