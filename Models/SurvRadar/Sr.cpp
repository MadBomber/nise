////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Sr.cpp
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

#include "Sr.hpp"
#include "SamsonHeader.h"
#include "DebugFlag.h"
#include "MessageFunctor.hpp"
#include <cmath>

int Sr::init (int argc, ACE_TCHAR *argv[])
{
	// setup the messages
	this->mTgtTruth = new TruthTargetStates();  // receive
	MessageFunctor<Sr>srfunctor(this,&Sr::processTargetInput);
	mTgtTruth->subscribe(&srfunctor,0);

	mTgtMeasured = new SrMeasuredTargetStates ();  // send

	// process the command line
	ACE_UNUSED_ARG(argc);
	ACE_UNUSED_ARG(argv);

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int Sr::fini (void)
{
	delete mTgtTruth;
	delete mTgtMeasured;
	return 1;
}

//...................................................................................................
int Sr::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	blindZone = 30000.0;
	//range = -999.0;
	return 1;
}

// ...................................................................................................
// Object mTgtTruth
int Sr::processTargetInput (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	SamsonMath::Vec3<double> position;
	double range;
	static bool print_once = true;

	//mTgtTruth->print();
	int tgtUnitID = mTgtTruth->unitID_;
	position = mTgtTruth->position_;

	range = sqrt(position.getX()*position.getX() +position.getY()*position.getY());
	//ACE_DEBUG ((LM_DEBUG, "Distance %f < %f\n",range,blindZone));
	if (range <= blindZone)
	{
		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG) && print_once )
		{
			print_once = false;
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) Sr::processTargetInput( Job:%d Msg:%d(%d) Mdl:%d.%d) -> Target Detected at t= %f for Target %d  \n",
				sh->run_id(),
				sh->message_id(),
				sh->app_msg_id(),
				sh->peer_id(),
				sh->unit_id(),
				this->currTime_,
				mTgtTruth->unitID_
				));
		}

		mTgtMeasured->time_     = currTime_;
		mTgtMeasured->position_ = position;
		mTgtMeasured->unitID_   = tgtUnitID;
		mTgtMeasured->publish(this->currFrame_, this->send_count_++, tgtUnitID);

	}
	return 1;
}

ACE_FACTORY_DECLARE(ISE,Sr)

