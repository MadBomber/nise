////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Missile.hpp
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

#ifndef _MISSILE_HPP
#define _MISSILE_HPP

#include "ISE.h"
#include "SamsonModel.h"
#include "MessageBase.h"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "LaunchCmd.hpp"
#include "TrkRadarUplink.hpp"
#include "MissileDownlink.hpp"
#include "MissileInitializePos.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer { class MessageBase; }

class ISE_Export Missile : public Samson_Peer::SamsonModel
{
	public:
		Missile(void);
		~Missile(void) {}
	
		// to get state information
		virtual int info (ACE_TCHAR **info_string, size_t length) const;
		ISE_Export friend ostream& operator<<(ostream& output, const Missile& p);

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		// base class needs 1 to continue
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }
		virtual int endSimulation (Samson_Peer::MessageBase *) { return 1; }

		int doStep (int mslUnitID);
		
		int doUplink (Samson_Peer::MessageBase *mb);
		int doLaunchCmd (Samson_Peer::MessageBase *mb);
	
	
	protected:

		#define ITEMS \
		ITEM(SamsonMath::Vec3<double>, missilePosition) \
		ITEM(SamsonMath::EulerAngles,  missileAttitude) \
		ITEM(bool,   launchMissile) \
		ITEM(double, initialTurnTime) \
		ITEM(double, xAxisMissile) \
		ITEM(double, yAxisMissile) \
		ITEM(double, zAxisMissile) \
		ITEM(double, xRangeInitial) \
		ITEM(double, xRangeTurn) \
		ITEM(double, launchTime) \
		ITEM(double, timeSinceLaunch) \
		ITEM(double, rollRate) \
		ITEM(double, rollMissile) \
		ITEM(double, pitchMissile) \
		ITEM(double, deltax) \
		ITEM(double, deltay) \
		ITEM(double, pitchdist ) \
		ITEM(double, yawMissile ) \
		ITEM(int,    stepSizeInitial ) \
		ITEM(int,    stepSizeTurn ) \
		ITEM(double, alphaInitial ) \
		ITEM(double, alphaTurn ) \
		ITEM(double, alphaY ) \
		ITEM(double, xAxisPrev) \
		ITEM(double, yAxisPrev) \
		ITEM(double, zAxisPrev)
		
//		#include "model_states.inc"

#define ITEM(TYPE, VAR) TYPE VAR;
		ITEMS
#undef ITEM

#if 0
public:

	template<class Archive>
	void serialize(Archive & ar, const unsigned int)
	{
/*
		ACE_UINT64 sys_time_usec;
		ACE_OS::gettimeofday().to_usec(sys_time_usec);
		ar & BOOST_SERIALIZATION_NVP(sys_time_usec);

		ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(Samson_Peer::SamsonModel);
*/
		
#define ITEM(TYPE, VAR) ar & BOOST_SERIALIZATION_NVP(VAR);
		ITEMS
#undef ITEM
	}

#endif

#undef ITEMS

		boost::scoped_ptr<MyMissileDownlink> mDownlink;
 		boost::scoped_ptr<LaunchCmd> mLaunchCmd;
  		boost::scoped_ptr<TrkRadarUplink> mUplink;
  		boost::scoped_ptr<MissileInitializePos> MissileToVat;

};

ACE_FACTORY_DEFINE(ISE,Missile)

#endif

