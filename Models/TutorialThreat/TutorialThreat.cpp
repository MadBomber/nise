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

#include "TutorialThreat.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "DebugFlag.h"

// used to get the command line
#include "ace/Get_Opt.h"

#include <stdio.h>    // to get "printf" function
#include <stdlib.h>   // to get "free" function
#include "XMLWrapper.h"


//...................................................................................................
TutorialThreat::TutorialThreat():
	SamsonModel(),
	mTgtTruth (new TruthTargetStates()),
	mTargetDestroyed (new TargetDestroyed())
{
}

//...................................................................................................
int TutorialThreat::init (int argc, ACE_TCHAR *argv[])
{
	// setup the messages to subscribe
	MessageFunctor<TutorialThreat> threat_endengage(this, &TutorialThreat::doTargetDestroyed);
	mTargetDestroyed->subscribe(&threat_endengage,-1); // trick to subscribe to MY unitid

	// set initial params of model
	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int TutorialThreat::fini (void)
{
	return 1;
}


int TutorialThreat::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	char errorMsg[1024];

	const char * elements[]	= {	"xAxis",	"yAxis",	"zAxis",	"stepSize",		"engagementTime",	0 };
	double * variables[]= { &xAxis,		&yAxis,		&zAxis,		&stepSize,		&engagementTime,	0 };
	double defaults[]	= {	0.00,		5000.00,	0.00,		1.00,			1000.00,			0 };

	ISEXMLWrapper_searchNodesAndFill(this->app_key_.c_str(), this->unit_id_, const_cast<char **>(elements), variables, defaults, errorMsg);

	return 1;
}

int TutorialThreat::MonteCarlo_Step (Samson_Peer::MessageBase *)
{
	ACE_DEBUG ((LM_DEBUG, "\n-------------------------------------------------------\n"));

	toDB("TutorialThreat");

	// Flies Target until end of specified time
	if (this->currTime_ < engagementTime)
	{
		xAxis = xAxis + stepSize;

		threatPosition.setXYZ (xAxis, yAxis, zAxis);
		threatAttitude.setXYZ (0.0, 0.0, 0.0);

		mTgtTruth->time_     = currTime_;
		mTgtTruth->position_ = threatPosition;
		mTgtTruth->attitude_ = threatAttitude;
		mTgtTruth->unitID_   = this->unit_id_;
		mTgtTruth->publish(this->currFrame_, this->send_count_++);

		ACE_DEBUG ((LM_DEBUG, " TargetModel::MonteCarlo_Step -> Published mTgtTruth (time %f): \n", this->currTime_));
	}
	else
	{
		ACE_DEBUG ((LM_DEBUG, " TargetModel::MonteCarlo_Step -> sending End Case (time %f): \n", this->currTime_));
		this->sendEndCase();
	}

	ACE_DEBUG ((LM_DEBUG, "-------------------------------------------------------\n"));
	return 1;
}

int TutorialThreat::doTargetDestroyed(Samson_Peer::MessageBase *)
{
	ACE_DEBUG ((LM_DEBUG, "\n-------------------------------------------------------\n"));
	ACE_DEBUG ((LM_DEBUG, " TargetModel::doTargetDestroyed -> sending End Case (time %f): \n", this->currTime_));
	ACE_DEBUG ((LM_DEBUG, "-------------------------------------------------------\n"));

	this->sendEndCase();

	return 1;
}

ACE_FACTORY_DECLARE(ISE,TutorialThreat)
