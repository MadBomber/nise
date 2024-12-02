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

#ifndef _TUTORIALMISSILE_HPP
#define _TUTORIALMISSILE_HPP

#include "ISE.h"

#include "SamsonModel.h"
#include "MessageBase.h"

#include "TruthTargetStates.hpp"
#include "TargetDestroyed.hpp"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer { class MessageBase; }

class ISE_Export TutorialMissile: public Samson_Peer::SamsonModel
{
	public:
		TutorialMissile();
		~TutorialMissile(){}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);
		
		virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *) { return 1; }
		virtual int endSimulation(Samson_Peer::MessageBase *) { return 1; }
		
		int processTargetTruthFromThreat(Samson_Peer::MessageBase *mb);
		

	protected:

		// MessageBase Objects
		boost::scoped_ptr<TruthTargetStates> mTgtTruth;
		boost::scoped_ptr<TruthTargetStates> mTgtTruthReceived;
		boost::scoped_ptr<TargetDestroyed> mTargetDestroyed;
	
		#define ITEMS \
		ITEM(SamsonMath::Vec3<double>, missilePosition) \
		ITEM(SamsonMath::EulerAngles,  missileAttitude) \
		ITEM(double, stepSize) \
		ITEM(double, xAxis) \
		ITEM(double, yAxis) \
		ITEM(double, zAxis) \
		ITEM(double, xAxisThreat) \
		ITEM(double, yAxisThreat) \
		ITEM(double, zAxisThreat)
		#include "model_states.inc"
};

ACE_FACTORY_DEFINE(ISE,TutorialMissile)

#endif
