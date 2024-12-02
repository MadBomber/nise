////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TargetModel.cpp
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

#include "TutorialMissile.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"

//...................................................................................................
TutorialMissile::TutorialMissile():
	SamsonModel(),
	mTgtTruth (new TruthTargetStates()),
	mTgtTruthReceived (new TruthTargetStates()),
	mTargetDestroyed (new TargetDestroyed())
{
}

//...................................................................................................
int TutorialMissile::init (int argc, ACE_TCHAR *argv[])
{
	// setup the messages to subscribe
	MessageFunctor<TutorialMissile> threat_tgttruthreceive(this, &TutorialMissile::processTargetTruthFromThreat);
	mTgtTruthReceived->subscribe(&threat_tgttruthreceive,0);

	// set initial params of model
	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int TutorialMissile::fini (void)
{
	return 1;
}


int TutorialMissile::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	// set initial params of threat
	stepSize = 100.0;

	xAxis = 0.0;
	yAxis = 0.0;
	zAxis = 0.0;

	xAxisThreat = -1.0;
	yAxisThreat = -1.0;
	zAxisThreat = -1.0;

	return 1;
}

int TutorialMissile::MonteCarlo_Step (Samson_Peer::MessageBase *)
{
	toDB("TutorialMissile");

	double stepSizeRemaining = stepSize;

	// Flies Target until end of specified time
	if ((xAxisThreat != -1.0) &&
		(yAxisThreat != -1.0) &&
		(zAxisThreat != -1.0))
	{
		//Compute new X Axis Location
		if (xAxisThreat <= (xAxis + stepSizeRemaining))
		{
			stepSizeRemaining = stepSizeRemaining - (xAxisThreat - xAxis);
			xAxis = xAxisThreat;
		}
		else
		{
			xAxis = xAxis + stepSizeRemaining;
			stepSizeRemaining = 0;
		}

		//Compute new Y Axis Location
		if (stepSizeRemaining > 0)
		{
			if (yAxisThreat <= (yAxis + stepSizeRemaining))
			{
				stepSizeRemaining = stepSizeRemaining - (yAxisThreat - yAxis);
				yAxis = yAxisThreat;
			}
			else
			{
				yAxis = yAxis + stepSizeRemaining;
				stepSizeRemaining = 0;
			}
		}

		missilePosition.setXYZ (xAxis, yAxis, zAxis);
		missileAttitude.setXYZ (0.0, 0.0, 0.0);

		mTgtTruth->time_     = currTime_;
		mTgtTruth->position_ = missilePosition;
		mTgtTruth->attitude_ = missileAttitude;
		mTgtTruth->unitID_   = this->unit_id_+1;
		mTgtTruth->publish(this->currFrame_, this->send_count_++);
		ACE_DEBUG ((LM_DEBUG, "\n-------------------------------------------------------\n"));
		ACE_DEBUG ((LM_DEBUG, "TutorialMissile::MonteCarlo_Step -> Published mTgtTruth (time %f): \n", this->currTime_));
		ACE_DEBUG ((LM_DEBUG, "Threat at (%f, %f, %f). Missile now at (%f, %f, %f) \n", xAxisThreat,yAxisThreat,zAxisThreat,xAxis,yAxis,zAxis));



		if ((xAxis == xAxisThreat) &&
			(yAxis == yAxisThreat))
		{
			mTargetDestroyed->time_   = currTime_;
			mTargetDestroyed->state_  = 1;
			mTargetDestroyed->unitID_ = 1;
			mTargetDestroyed->publish(this->currFrame_, this->send_count_++, 1);

			ACE_DEBUG ((LM_DEBUG, "TutorialMissile::MonteCarlo_Step -> Published Target Destroyed \n"));
		}

		ACE_DEBUG ((LM_DEBUG, "-------------------------------------------------------\n"));

	}

	return 1;
}

int TutorialMissile::processTargetTruthFromThreat(Samson_Peer::MessageBase *)
{
	if (mTgtTruthReceived->unitID_ == 1)
	{
		xAxisThreat = mTgtTruthReceived->position_.getX();
		yAxisThreat = mTgtTruthReceived->position_.getY();
		zAxisThreat = mTgtTruthReceived->position_.getZ();

		ACE_DEBUG ((LM_DEBUG, "\n-------------------------------------------------------\n"));
		ACE_DEBUG ((LM_DEBUG, "TargetModel::processTargetTruthFromThreat -> Storing Threat Information (time %f): \n", this->currTime_));
		ACE_DEBUG ((LM_DEBUG, "Threat at (%f, %f, %f) \n", xAxisThreat, yAxisThreat, zAxisThreat));
		ACE_DEBUG ((LM_DEBUG, "-------------------------------------------------------\n"));
	}

	return 1;
}

ACE_FACTORY_DECLARE(ISE,TutorialMissile)
