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

#ifndef _VAT_LOG_DATA_HPP
#define _VAT_LOG_DATA_HPP


#include "ace/High_Res_Timer.h"

#include "ISE.h"

#include "SamsonModel.h"

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

//... boost smart pointers
#include <boost/scoped_ptr.hpp>


namespace Samson_Peer { class MessageBase; }

class ISE_Export VatLogData : public Samson_Peer::SamsonModel
{
	public:
		VatLogData();
		~VatLogData(){}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);
		
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *mb);
		virtual int endSimulation (Samson_Peer::MessageBase *) { return 1; }
		
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

	protected:

		int processData (int ndx);
		
		void print(int index);

		int numberUnitID;

		bool prelnch[3];
		bool msldatrcv[3];
		bool tgtdatrcv[3];
		bool printmetgtaway[3];
		bool printmetgtdst[3];
		bool printmeSR[3];
		bool printmeMFCRTgt[3];
		bool printmeMFCRMsl[3];
		bool pDataflag[3];

	private:
		int iDataCount[3];
		int dataSize;
		SamsonMath::Vec3<double> srPosition;

		struct dataLogStruct
		{
			double simTime;
			SamsonMath::Ned TgtPosition;
			SamsonMath::EulerAngles TgtAttitude;
			SamsonMath::Ned MslPosition;
			SamsonMath::EulerAngles MslAttitude;
		};

		struct dataLogStruct *pSaveDataStart[3], dataLogData[3];

		boost::scoped_ptr<MyMissileDownlink> MissileToTrkRadarOutput;
		boost::scoped_ptr<TruthTargetStates> mTargetState;
		boost::scoped_ptr<LaunchCmd> mLaunchCmd;
		boost::scoped_ptr<TargetDestroyed> mTargetDestroyed;
		boost::scoped_ptr<TrkRadarOnCmd> TocToTrkRadar;
		boost::scoped_ptr<LaunchRequest> mLaunchRequest;
		boost::scoped_ptr<SrMeasuredTargetStates> SrOutput;
		boost::scoped_ptr<TrkRadarMeasuredTargetStates> TrkRadarToToc;
		boost::scoped_ptr<TrkRadarUplink> TrkRadarInputMissile;
		boost::scoped_ptr<MissileInitializePos> MissileToVat;		

		// Elapsed time the module is loaded
		ACE_High_Res_Timer vat_timer_;

		
#if 0
		typedef boost::array<bool,3> Bool3;
		typedef boost::array<int,3>  Int3;
		typedef boost::array<SamsonMath::Vec3<double>,3> ArrVec3;
	
		#define ITEMS \
		ITEM(int,    numberUnitID) \
		ITEM(Bool3,  prelnch) \
		ITEM(Bool3,  msldatrcv) \
		ITEM(Bool3,  tgtdatrcv) \
		ITEM(Bool3,  printmetgtaway) \
		ITEM(Bool3,  printmetgtdst) \
		ITEM(Bool3,  printmeSR) \
		ITEM(Bool3,  printmeMFCRTgt) \
		ITEM(Bool3,  printmeMFCRMsl) \
		ITEM(Bool3,  pDataflag) \
		ITEM(Int3,   iDataCount) \
		ITEM(int,    dataSize) \
		ITEM(SamsonMath::Vec3<double>, srPosition) \
		ITEM(SamsonMath::Vec3<double>, mfcrPosition) \
		ITEM(ArrVec3,                  missilePosition) \
		ITEM(double, positionUplink) \
		ITEM(Bool3,  trkRadarOn)
		#include "model_states.inc"
#endif
};

ACE_FACTORY_DEFINE(ISE,VatLogData)


#endif
