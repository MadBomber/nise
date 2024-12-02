////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TrkRadar.hpp
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

#ifndef _TRKRADAR_HPP
#define _TRKRADAR_HPP

#include "ISE.h"

#include "SamsonModel.h"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "TruthTargetStates.hpp"
#include "TrkRadarOnCmd.hpp"
#include "TrkRadarMeasuredTargetStates.hpp"
#include "TrkRadarUplink.hpp"
#include "MissileDownlink.hpp"
#include "LaunchCmd.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>

namespace Samson_Peer
{
class MessageBase;
}

//.........................................................................
class ISE_Export TrkRadar : public Samson_Peer::SamsonModel
{
public:
	TrkRadar();
	~TrkRadar()
	{}

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { if ( this->save_state_ ) toDB("TrkRadar"); return 1;}
	virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) {return 1;}
	virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) {return 1;}
	virtual int endSimulation (Samson_Peer::MessageBase *) {return 1;}

	int processTrkRadarOn (Samson_Peer::MessageBase *mb);
	int doTrackTarget (Samson_Peer::MessageBase *mb);
	int processDownlink (Samson_Peer::MessageBase *mb);
	int missileAway (Samson_Peer::MessageBase *mb);

	enum targetType
	{	ABT, TBM, UNKNOWN};
	targetType targetId;

	bool launchMissile[3];

private:

	// MessageBase Objects
	boost::scoped_ptr<MyMissileDownlink> mDownlink;
	boost::scoped_ptr<TrkRadarUplink> mUplink;
	boost::scoped_ptr<TruthTargetStates> mTgtTruth;
	boost::scoped_ptr<TrkRadarOnCmd> mRadarOn;
	boost::scoped_ptr<LaunchCmd> mLaunchCmd;
	boost::scoped_ptr<TrkRadarMeasuredTargetStates> TrkRadarToToc;

	typedef boost::array<bool,3> Bool3;
	typedef boost::array<SamsonMath::Vec3<double>,3> ArrVec3;
	typedef boost::array<double,3> Double3;

	ArrVec3 mfcrPosition;
	ArrVec3 missilePosition;
	Double3 timeStampRadarOn;
	double positionUplink;
	Bool3  trkRadarOn;
};

ACE_FACTORY_DEFINE(ISE,TrkRadar)

#endif

