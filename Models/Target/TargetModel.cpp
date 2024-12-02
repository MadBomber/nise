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

#include "TargetModel.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "Constants.hpp"
#include "DebugFlag.h"
#include "XMLWrapper.h"

#include <assert.h>
#include <cmath>
#include <sstream>
#include <string>


//...................................................................................................
TargetModel::TargetModel():
		SamsonModel(),
		engagementTime(0.0),
		stepSize(0.0),
		xRange(0.0),
		yAxis(0.0),
		zAxis(0.0),
		roll(0.0),
		pitch(0.0),
		yaw(0.0),
		alpha(0.0),
		alphaZ(0.0),
		alphaZA(0.0),
		xInitialCondition(0.0),
		xAxisPrev(0.0),
		yAxisPrev(0.0),
		zAxisPrev(0.0),
		destroyed(0.0),
		mTgtTruth (new TruthTargetStates ()),  // send
		mTargetDestroyed (new TargetDestroyed())
{
	this->position_.setXYZ (xAxisPrev, yAxisPrev, zAxisPrev);
	this->attitude_.setXYZ (roll, pitch, yaw);
}

//...................................................................................................
int TargetModel::info (ACE_TCHAR **info_string, size_t length) const
{
	std::stringstream myinfo;

	//this->toText(myinfo);
	//myinfo << std::endl;

	myinfo << *this;

	if (*info_string == 0)
		*info_string = ACE::strnew(myinfo.str().c_str());
	else
		ACE_OS::strncpy(*info_string, myinfo.str().c_str(), length);

	return ACE_OS::strlen(*info_string) +1;
}


//...................................................................................................
ISE_Export ostream& operator<<(ostream& output, const TargetModel& p)
{
    output << dynamic_cast< const Samson_Peer::SamsonModel&>(p) << std::endl;

    output << "TargetModel:: ";
    output << " position: " << p.position_;
    output << " attitude: " << p.attitude_;
    output << " engagementTime: " << p.engagementTime;
    output << " stepSize: " << p.stepSize << std::endl;

    output << " xAxis: " << p.xAxis;
    output << " yAxis: "  << p.yAxis;
    output << " zAxis: "  << p.zAxis;
    output << " roll: "  << p.roll;
    output << " pitch: "  << p.pitch;
    output << " yaw: "  << p.yaw;
    output << " alpha: "  << p.alpha;
    output << " alphaZ: "  << p.alphaZ;
    output << " alphaZA: "  << p.alphaZA;

    output << " xAxisPrev: "  << p.xAxisPrev;
    output << " yAxisPrev: "  << p.yAxisPrev;
    output << " zAxisPrev: "  << p.zAxisPrev;

    return output;
}

//...................................................................................................
int TargetModel::init(int argc, ACE_TCHAR *argv[])
{
	MessageFunctor<TargetModel>tgtdestroyed(this,&TargetModel::doTargetDestroyed);
	mTargetDestroyed->subscribe(&tgtdestroyed,-1);

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

int TargetModel::doTargetDestroyed (Samson_Peer::MessageBase *)
{
	this->destroyed = true;
	return 1;
}

//...................................................................................................
int TargetModel::fini(void)
{
	return 1;
}

//...................................................................................................
int TargetModel::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	char errorMsg[1024];

	const char *elements[]	= {	"xInitCond",		"xRange",		"stepSize",		"yAxis",	"pitch",
					"xAxisPrev",		"yAxisPrev",		"zAxisPrev",		"alphaZ",	"alphaZA",
					"engagementTime",	"roll",			"yaw",			0 };

	double * variables[]= { &xInitialCondition,	&xRange,		&stepSize,			&yAxis,		&pitch,
				&xAxisPrev,		&yAxisPrev,		&zAxisPrev,			&alphaZ,	&alphaZA,
				&engagementTime,	&roll,			&yaw,				0 };

	double defaults[]	= {	40000,		40000.0-13333.33,	1999,				0,		116.5,
					0.00,		0.00,			0.00,				1.00,		0.00,
					200.00,		0.00,			0.00,				0 };

	int status = ISEXMLWrapper_searchNodesAndFill(this->app_key_.c_str(), this->unit_id_, const_cast<char **>(elements), variables, defaults, errorMsg);
	ACE_DEBUG((LM_DEBUG, "App Key: %s, Unit ID: %d, Status: %d, Msg: %s\n", this->app_key_.c_str(), this->unit_id_, status, errorMsg));

	this->position_.setXYZ (xAxisPrev, yAxisPrev, zAxisPrev);

	pitch= 0; // this seems silly??
	this->attitude_.setXYZ (roll, pitch, yaw);

	alpha  = (xRange / stepSize);
	xAxis = xInitialCondition;
	yAxis = yAxisPrev;

	// this model will send an end of engagement
	this->sendRegisterEndEngage();

	return 1;
}

int TargetModel::MonteCarlo_Step (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	static int print_once = true;
	int result = 1;

	// archive the data to the model database
	if ( this->save_state_ ) this->toDB("TargetModel");

	// Flies Target until end of specified time
	if (this->currTime_ < engagementTime)
	{
		if (!this->destroyed)
		{
			xAxisPrev  = xAxis;
			yAxisPrev  = yAxis;
			zAxisPrev  = zAxis;

			xAxis  = (xAxisPrev  - alpha);
			zAxis = (alphaZ*(0.00005 * (xAxis * xAxis) - 2 * xAxis)+alphaZA);
			yAxis = yAxisPrev;

			roll  = 0.0;
			pitch  = atan2(-(zAxis- zAxisPrev),(xAxis - xAxisPrev)) * SamsonMath::RAD_TO_DEG;
			yaw = 0.0;

			this->position_.setXYZ (xAxis, yAxis, zAxis);
			this->attitude_.setXYZ (roll, pitch, yaw);

			mTgtTruth->time_     = this->currTime_;
			mTgtTruth->position_ = this->position_;
			mTgtTruth->attitude_ = this->attitude_;
			mTgtTruth->unitID_   = this->unit_id_;
			mTgtTruth->publish(this->currFrame_, this->send_count_++);
		}
	}
	else
	{
		if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG) && print_once )
		{
			print_once = false;
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) TargetModel::MonteCarlo_Step( Job:%d Msg:%d(%d) Mdl:%d.%d ) -> Ending Engagement t= %f\n",
				sh->run_id(),
				sh->message_id(),
				sh->app_msg_id(),
				sh->peer_id(),
				sh->unit_id(),
				this->currTime_
				));
		}

		this->sendEndEngage ();
	}

	return result ;
}


//...................................................................................................
void TargetModel::print(void)
{
	ACE_DEBUG((LM_INFO,"(%P|%t) TargetModel at time %f (%f,%f,%f) (%f,%f,%f)\n",
			   currTime_, xAxis, yAxis, zAxis, roll, pitch, yaw));
}

// Used by the service factory to create/destroy the model
ACE_FACTORY_DECLARE(ISE,TargetModel)

