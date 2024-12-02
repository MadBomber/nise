////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TargetModel.hpp
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

#ifndef _TARGET_HPP
#define _TARGET_HPP

#include "ISE.h"

#include "SamsonModel.h"
#include "MessageBase.h"

#include "Messages/EndEngagement.h"

#include "TruthTargetStates.hpp"
#include "TargetDestroyed.hpp"

#include "Vec3.hpp"
#include <iostream>
#include <fstream>
#include "EulerAngles.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer
{
class MessageBase;
}

class ISE_Export TargetModel: public Samson_Peer::SamsonModel
{
public:

	TargetModel();
	~TargetModel() {}

	// to get state information
	virtual int info (ACE_TCHAR **info_string, size_t length) const;
	ISE_Export friend ostream& operator<<(ostream& output, const TargetModel& p);

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) {return 1;}
	virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *){return 1;}
	virtual int endSimulation(Samson_Peer::MessageBase *){return 1;}
	int doTargetDestroyed (Samson_Peer::MessageBase *mb);

protected:
	ifstream inputFile;

	void print(void);

		#define ITEMS \
		ITEM(SamsonMath::Vec3<double>, position_) \
		ITEM(SamsonMath::EulerAngles,  attitude_) \
		ITEM(double, engagementTime) \
        ITEM(double, stepSize) \
		ITEM(double, xRange) \
		ITEM(double, xAxis) \
		ITEM(double, yAxis) \
		ITEM(double, zAxis) \
		ITEM(double, roll) \
		ITEM(double, pitch) \
		ITEM(double, yaw) \
		ITEM(double, alpha) \
		ITEM(double, alphaZ) \
		ITEM(double, alphaZA) \
		ITEM(double, xInitialCondition ) \
		ITEM(double, xAxisPrev) \
		ITEM(double, yAxisPrev) \
		ITEM(double, zAxisPrev) \
		ITEM(bool,   destroyed)
		#include "model_states.inc"

	boost::scoped_ptr<TruthTargetStates> mTgtTruth;
	boost::scoped_ptr<TargetDestroyed> mTargetDestroyed;
};

ACE_FACTORY_DEFINE(ISE,TargetModel)

#endif
