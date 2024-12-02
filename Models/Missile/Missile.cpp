   ////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Missile.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Nancy Anderson
//					 Adel Klawitter
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

#include "Missile.hpp"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "Constants.hpp"
#include "MessageFunctor.hpp"
#include <math.h>

//...................................................................................................
Missile::Missile(void): SamsonModel(),
mDownlink (new MyMissileDownlink()),
mLaunchCmd (new LaunchCmd()),
mUplink (new TrkRadarUplink()),
MissileToVat (new MissileInitializePos())
{
	launchMissile = false;
	initialTurnTime = 0.0;
	xAxisMissile = 0.0;
	yAxisMissile = 0.0;
	zAxisMissile = 0.0;
	xRangeInitial = 0.0;
	xRangeTurn = 0.0;
	launchTime = 0.0;
	timeSinceLaunch = 0.0;
	rollRate = 0.0;
	rollMissile = 0.0;
	pitchMissile = 0.0;
	deltax = 0.0;
	deltay = 0.0;
	pitchdist = 0.0;
	yawMissile  = 0.0;
	stepSizeInitial = 0;
	stepSizeTurn= 0;
	alphaInitial = 0.0;
	alphaTurn  = 0.0;
	alphaY = 0.0;
	xAxisPrev = 0.0;
	yAxisPrev = 0.0;
	zAxisPrev = 0.0;

	missilePosition.setXYZ (xAxisMissile, yAxisMissile, zAxisMissile);
	missileAttitude.setXYZ (rollMissile, pitchMissile, yawMissile);
}

//...................................................................................................
int Missile::info (ACE_TCHAR **info_string, size_t length) const
{
	std::stringstream myinfo;
	myinfo << *this;
	//this->toText(myinfo);

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}


//...................................................................................................
ISE_Export ostream& operator<<(ostream& output, const Missile& p)
{
    output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

    output << "Missile:: ";
    output	<< " missilePosition: " << p.missilePosition;
    output	<< " missileAttitude: " << p.missileAttitude;
    output	<< " LaunchMissile: " << p.launchMissile;
    output	<< " initialTurnTime: " << p.initialTurnTime;
    output	<< " xAxisMissile: " << p.xAxisMissile;
    output	<< " yAxisMissile: " << p.yAxisMissile;
    output	<< " zAxisMissile: " << p.zAxisMissile;
    output	<< " xRangeInitial: " << p.xRangeInitial;
    output	<< " xRangeTurn: " << p.xRangeTurn;
    output	<< " launchTime: " << p.launchTime;
    output	<< " timeSinceLaunch: " << p.timeSinceLaunch;
    output	<< " rollRate: " << p.rollRate;
    output	<< " rollMissile: " << p.rollMissile;
    output	<< " pitchMissile: " << p.pitchMissile;
    output	<< " deltax: " << p.deltax;
    output	<< " deltay: " << p.deltay;
    output	<< " pitchdist: " << p.pitchdist;
    output	<< " yawMissile: " << p.yawMissile;
    output	<< " stepSizeInitial: " << p.stepSizeInitial;
    output	<< " stepSizeTurn: " << p.stepSizeTurn;
    output	<< " alphaInitial: " << p.alphaInitial;
    output	<< " alphaTurn: " << p.alphaTurn;
    output	<< " alphaY: " << p.alphaY;
    output	<< " xAxisPrev: " << p.xAxisPrev;
    output	<< " yAxisPrev: " << p.yAxisPrev;
    output	<< " zAxisPrev: " << p.zAxisPrev;

    return output;
}


//...................................................................................................
//...................................................................................................
//...................................................................................................
int Missile::init (int argc, ACE_TCHAR *argv[])
{
	MessageFunctor<Missile> uplink_functor (this, &Missile::doUplink);
	mUplink->subscribe(&uplink_functor,-1);  // trick to subscribe to MY unitid

	MessageFunctor<Missile> lm_functor(this, &Missile::doLaunchCmd);
	mLaunchCmd->subscribe(&lm_functor,-1); // trick to subscribe to MY unitid

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int Missile::fini (void)
{
	return 1;
}

//...................................................................................................
int Missile::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	double temp[] = { 0.0, (10000.0/29.9), -(15000.0/29.9) };
	//double xRangeTurn;

	initialTurnTime          = 3;
	stepSizeInitial          = 30;
	stepSizeTurn             = 269;
	xRangeInitial            = 868.241;
	xRangeTurn               = 13333.33 - xRangeInitial;
	alphaInitial             = (xRangeInitial / stepSizeInitial) * this->timing_.frequency();
	alphaTurn                = (xRangeTurn / stepSizeTurn) * this->timing_.frequency();
	rollRate                 = (360.0 / 2.0);

	launchMissile = false;
	launchTime = -999.0;
	xAxisMissile = 0.0;
	yAxisMissile = 0.0;
	zAxisMissile = 0.0;
	timeSinceLaunch = 0.0;
	rollMissile = 0.0;
	pitchMissile = 80.0;
	xAxisPrev = 0;
	yAxisPrev = 0;
	zAxisPrev = 0;

	//initialize different missiles
	alphaY = temp[this->unit_id_-1];

	return 1;

}

int Missile::doUplink(Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	// TODO  put in message when subscribe ??
	int mslUnitID = sh->unit_id();
	return doStep (mslUnitID);
}

int Missile::doLaunchCmd (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	// TODO verify that the unit_id's are the same

	unsigned int mslUnitID = mLaunchCmd->unitID_;

	launchTime = mLaunchCmd->time_;
	launchMissile = true;


	if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG, " Missile::doLaunchCmd(%d:%d(%d):%d:%d) -> Launched at t= %f (%f) for Missile %d  \n",
			sh->run_id(),
			sh->message_id(),
			sh->app_msg_id(),
			sh->peer_id(),
			sh->unit_id(),
			this->currTime_,
			launchTime,
			mslUnitID
			));
	}

	return 1;
}

/*
There two inputs are  uplink and launch, for this example they are
mutually exclusive and the an uplink is required to fly,

Now, we know this is just not how it happens and though I do not have
the full facts on the expected sequence of events, this is good enough
to make this 'simplified' example work.

Jackal  March 2006
*/

int Missile::doStep (int mslUnitID)
{
	// this links the Missile N to Target N
	int ndx = mslUnitID -1;

	if (launchMissile)
	{
		if (currTime_ >= launchTime)
		{
			xAxisPrev = xAxisMissile;
			yAxisPrev = yAxisMissile;
			zAxisPrev = zAxisMissile;
			timeSinceLaunch = currTime_ - launchTime;
			if(currTime_ <= (launchTime + initialTurnTime))
			{
				xAxisMissile = (alphaInitial * timeSinceLaunch);
				yAxisMissile = (alphaY * timeSinceLaunch);
				zAxisMissile = -(5.67128 * xAxisMissile);
			}
			else
			{
				xAxisMissile = (alphaTurn * (timeSinceLaunch - initialTurnTime) + xRangeInitial);
				yAxisMissile = (alphaY * timeSinceLaunch);
				zAxisMissile = (((0.082725 *
						(xAxisMissile *SamsonMath::M_TO_KM * xAxisMissile*SamsonMath::M_TO_KM)) -
						(2.205994 * xAxisMissile*SamsonMath::M_TO_KM) - 3.07111) *SamsonMath::KM_TO_M);
			}
			if (timeSinceLaunch > 0)
			{
				rollMissile += (rollRate * this->timing_.rate());
				rollMissile = (rollMissile < 360.0 ) ? rollMissile : rollMissile-360.0;
				deltax = ((xAxisMissile - xAxisPrev)*(xAxisMissile - xAxisPrev));
				deltay = ((yAxisMissile - yAxisPrev)*(yAxisMissile - yAxisPrev));
				pitchdist = (sqrt(deltax + deltay));
				pitchMissile = atan2(-(zAxisMissile - zAxisPrev),pitchdist) * SamsonMath::RAD_TO_DEG;
				if(currTime_ <= (launchTime + initialTurnTime))
				{
					double tempyawinit[] = {0.0, 48.0, -58.7};
					yawMissile = tempyawinit[ndx];
				}
				else
				{
					double tempyaw[] = { 0.0, 35.6, -47.45 };
					yawMissile = tempyaw[ndx];
				}
			}
		}

		missilePosition.setXYZ (xAxisMissile, yAxisMissile, zAxisMissile);
		missileAttitude.setXYZ (rollMissile, pitchMissile, yawMissile);

		// Note that the "aDownlink variable contains the message object, but "mDownlink" does the sending
                mDownlink->time_    =currTime_;
		mDownlink->position_=missilePosition;
		mDownlink->attitude_=missileAttitude;
		mDownlink->unitID_  =this->unit_id_;
		mDownlink->publish(this->currFrame_, this->send_count_++);
	}

	return 1;
}

int Missile::MonteCarlo_Step(Samson_Peer::MessageBase *)
{
	if ( this->save_state_ )this->toDB("Missile");
	static bool once=false;
	// Report to VAT
	if (!once)
	{
		once=true;
		missilePosition.setXYZ(xAxisMissile, yAxisMissile, zAxisMissile);
		missileAttitude.setXYZ(rollMissile, pitchMissile, 0.0);

		MissileToVat->time_ =currTime_;
		MissileToVat->position_=missilePosition;
		MissileToVat->attitude_=missileAttitude;
		MissileToVat->unitID_=this->unit_id_;
		MissileToVat->publish(this->currFrame_, this->send_count_++);
	}

	return 1;
}

ACE_FACTORY_DECLARE(ISE,Missile)
