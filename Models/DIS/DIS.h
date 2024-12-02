////////////////////////////////////////////////////////////////////////////////
//
// Filename:         DIS.h
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        ISE_Models/DIS
//
// System Name:      DIS
//
// Description:
//
// Author:           Phillip Thompson
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

#ifndef _DB_LOGGER_HPP
#define _DB_LOGGER_HPP

#include "ISE.h"
#include "SamsonModel.h"
#include "DBMgr.h"

// UDP Broadcast
#include "ace/SOCK_Dgram_Bcast.h"

// UDP Point-to-Point Send
#include "ace/SOCK_Dgram.h"

//....boost smart pointer
#include <boost/shared_ptr.hpp>

#include "Ned.hpp"
#include "Vec3.hpp"

#include "TruthTargetStates.hpp"  //Publishes Target Position and Attitude
#include "MissileDownlink.hpp"    //Publishes Missile Position and Attitude
#include "LLA_Vehicle_State.hpp"


namespace Samson_Peer { class MessageBase; }

class ISE_Export DIS : public Samson_Peer::SamsonModel
{
public:
	DIS();
	~DIS()
	{}

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *)
	{	return 1;}
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *)
	{	return 1;}
	virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *)
	{	return 1;}
	virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *)
	{	return 1;}

	int processTarget (Samson_Peer::MessageBase *mb);
	int processMissile (Samson_Peer::MessageBase *mb);
	int processLaunchMissile (Samson_Peer::MessageBase *mb);
	int doTargetDestroyed (Samson_Peer::MessageBase *mb);
	int processTrkRadarOnCmd (Samson_Peer::MessageBase *mb);
	int processSrMeasuredTargetStates (Samson_Peer::MessageBase *mb);
	int doLaunchRequest (Samson_Peer::MessageBase *mb);
	int processTrkRadarMeasuredTargetStates (Samson_Peer::MessageBase *mb);
	int processTrkRadarUplink (Samson_Peer::MessageBase *mb);
	int processMissileInit (Samson_Peer::MessageBase *mb);
	int processLLA(Samson_Peer::MessageBase *mb);

private:
	int processToDIS (Samson_Peer::MessageBase *mb,
	                  double N, double E, double D,
			  double Y, double P, double R, bool friendly);

	int toDIS(Samson_Peer::MessageBase *mb, double t,
                  double lat, double lon,   double alt,
                  float  vx,  float  vy,    float  vz,
                  float  psi, float  theta, float phi,
                  bool friendly);

	boost::scoped_ptr<MyMissileDownlink> MissileToTrkRadarOutput;
	boost::scoped_ptr<TruthTargetStates> mTargetState;
	boost::scoped_ptr<LLA_Vehicle_State> mLLA_Vehicle_State;

	//ACE_SOCK_Dgram_Bcast dis_socket;
	ACE_SOCK_Dgram dis_socket;
};

ACE_FACTORY_DEFINE(ISE,DIS)


#endif
