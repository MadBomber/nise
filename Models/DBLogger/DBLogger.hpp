////////////////////////////////////////////////////////////////////////////////
//
// Filename:         VatLogData.hpp
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
//                   Adel Klawitter
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

//....boost smart pointer
#include <boost/shared_ptr.hpp>

#include "Ned.hpp"
#include "Vec3.hpp"

#include "TruthTargetStates.hpp"//Publishes Target Position and Attitude
#include "MissileDownlink.hpp"  //Publishes Missile Position and Attitude
#include "LaunchCmd.hpp"        //Publishes LaunchCmd from lnchr to msl (flag)
#include "TargetDestroyed.hpp"  //Publishes Target Destroyed Message (flag)
#include "TrkRadarOnCmd.hpp"        //Publishes MFCR on command (flag)
#include "LaunchRequest.hpp"    //Publishes Launch request from TocToLnchr (flag)
#include "SrMeasuredTargetStates.hpp"   //Publishes Surveillance radar targetstate position
#include "TrkRadarMeasuredTargetStates.hpp" //Publishes MFCR targetstate position
#include "TrkRadarUplink.hpp"       //Publishes MFCR uplink position (missile)
#include "MissileInitializePos.hpp" //Publishes Missile Initial Position and Attitude
#include "../CMD/msg/CMD_TargetState.h" //Publishes CMD Target State

#include "LLA_Vehicle_State.hpp"

namespace Samson_Peer { class MessageBase; }

class ISE_Export DBLogger : public Samson_Peer::SamsonModel
{
	public:
		DBLogger():SamsonModel(){}
		~DBLogger(){}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *mb);
/*
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
*/
	private:
		//MyMissileDownlink  aDownlink;
		//ObjMessageTempl<MyMissileDownlink> *MissileToTrkRadarOutput;
		MyMissileDownlink *MissileToTrkRadarOutput;

		TruthTargetStates *mTargetState;
		LaunchCmd *mLaunchCmd;
		TargetDestroyed *mTargetDestroyed;
		TrkRadarOnCmd *TocToTrkRadar;
		LaunchRequest *mLaunchRequest;
		SrMeasuredTargetStates *SrOutput;
		TrkRadarMeasuredTargetStates *TrkRadarToToc;
		TrkRadarUplink *TrkRadarInputMissile;
		MissileInitializePos *MissileToVat;
		CMD_TargetState *cmdTgtState;
		LLA_Vehicle_State *mLLATruth;


};

ACE_FACTORY_DEFINE(ISE,DBLogger)


#endif
