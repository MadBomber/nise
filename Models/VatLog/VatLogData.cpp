////////////////////////////////////////////////////////////////////////////////
//
// Filename:         VatLogData.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Adel Klawitter
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

#include "VatLogData.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "DebugFlag.h"
#include "Model_ObjMgr.h"

#include "SimMsgFlag.h"
#include "SimMsgType.h"

#include <string>
#include <fstream>


//.................................................................................
VatLogData::VatLogData():
	SamsonModel(),
	MissileToTrkRadarOutput( new MyMissileDownlink()),
	mTargetState (new TruthTargetStates()),
	mLaunchCmd (new LaunchCmd()),
	mTargetDestroyed (new TargetDestroyed()),
	TocToTrkRadar (new TrkRadarOnCmd()),
	mLaunchRequest (new LaunchRequest()),
	SrOutput (new SrMeasuredTargetStates()),
	TrkRadarToToc (new TrkRadarMeasuredTargetStates()),
	TrkRadarInputMissile (new TrkRadarUplink()),
	MissileToVat (new MissileInitializePos())
{
}


//.................................................................................
int VatLogData::init(int argc, ACE_TCHAR *argv[])
{
	this->vat_timer_.start ();

	if (Samson_Peer::DebugFlag::instance ()->enabled (Samson_Peer::DebugFlag::MDL_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG, "VatLogData::init() called\n"));
	}

	// Subscribe to missile info
	MessageFunctor<VatLogData>mfrcoutput(this,&VatLogData::processMissile);
	MissileToTrkRadarOutput->subscribe(&mfrcoutput,0);

	 //Subscribe to target info
	MessageFunctor<VatLogData>targetoutput(this,&VatLogData::processTarget);
	mTargetState ->subscribe(&targetoutput,0);

	MessageFunctor<VatLogData>missileinput(this,&VatLogData::processLaunchMissile);
	mLaunchCmd->subscribe(&missileinput,0);      //Subscribe to launch command

	MessageFunctor<VatLogData>tocendengage(this,&VatLogData::doTargetDestroyed);
	mTargetDestroyed ->subscribe(&tocendengage,0);      //Subscribe to Target Destroyed

	MessageFunctor<VatLogData>toctomfcr(this,&VatLogData::processTrkRadarOnCmd);
	TocToTrkRadar    ->subscribe(&toctomfcr,0);      //Subscribe to the MFCR On Command

	MessageFunctor<VatLogData>sroutput(this,&VatLogData::processSrMeasuredTargetStates);
	SrOutput     ->subscribe(&sroutput,0);

	MessageFunctor<VatLogData>toctolauncher(this,&VatLogData::doLaunchRequest);
	mLaunchRequest->subscribe(&toctolauncher,0);

	MessageFunctor<VatLogData>mfcrtotoc(this,&VatLogData::processTrkRadarMeasuredTargetStates);
	TrkRadarToToc    ->subscribe(&mfcrtotoc,0);

	MessageFunctor<VatLogData>mfcrinput(this,&VatLogData::processTrkRadarUplink);
	TrkRadarInputMissile->subscribe(&mfcrinput,0);

	MessageFunctor<VatLogData>missiletovat(this,&VatLogData::processMissileInit);
	MissileToVat ->subscribe(&missiletovat,0);

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

//...................................................................................................
int VatLogData::fini(void) //print missile and target data to file
{
	return 1;
}

//...................................................................................................
int VatLogData::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
	numberUnitID = 3;

	for (int i=0; i<numberUnitID; ++i)
	{
		prelnch[i] = false;
		msldatrcv[i] = false;
		tgtdatrcv[i] = false;
		pDataflag[i] = false;
		printmetgtaway[i] = true;
		printmetgtdst[i] = true;
		printmeSR[i] = true;
		printmeMFCRTgt[i] = true;
		printmeMFCRMsl[i] = true;
		iDataCount[i] = 0;


	}

	//Initialize structure for holding data to be used in the vat
	double testTime    = 250;
	double loggingStep = 0.1;
	dataSize           = int(testTime/loggingStep);
	for (int i=0; i<numberUnitID; ++i)
	{
		pSaveDataStart[i] = new struct dataLogStruct[dataSize]; // TODO test for allocation
		iDataCount[i] = 0;
		if (!pSaveDataStart)
		{
			ACE_DEBUG((LM_ERROR,"(%P|%t) VatLogData::MonteCarlo_InitCase -> Could not allocate memory for Data Logging\n"));
		}
	}

	return 1;
}
//.................................................................................
int VatLogData::processMissileInit (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int ndx =  sh->unit_id()  -1;
	prelnch[ndx] = true;
	dataLogData[ndx].MslPosition = MissileToVat->position_;
	dataLogData[ndx].MslAttitude = MissileToVat->attitude_;

	return processData(ndx);
}

//.................................................................................
int VatLogData::processMissile (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int ndx =  sh->unit_id()  -1;
	msldatrcv[ndx] = true;
	dataLogData[ndx].MslPosition = MissileToTrkRadarOutput->position_;
	dataLogData[ndx].MslAttitude = MissileToTrkRadarOutput->attitude_;

	return processData(ndx);
}

//.................................................................................
int VatLogData::processTarget (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int tgtUnitID = mTargetState->unitID_;
	int ndx = tgtUnitID-1;

	tgtdatrcv[ndx] = true;
	dataLogData[ndx].TgtPosition = mTargetState->position_;
	dataLogData[ndx].TgtAttitude = mTargetState->attitude_;

	if (printmetgtaway[ndx])
	{
		ACE_DEBUG ((LM_DEBUG, "*** Target %d In Flight ",sh->unit_id()));
		ACE_DEBUG ((LM_DEBUG, "Received at T:%f, N:%d, P:(%f %f %f)\n", currTime_, ndx, dataLogData[ndx].TgtPosition.getX(), dataLogData[ndx].TgtPosition.getY(), dataLogData[ndx].TgtPosition.getZ()));
		printmetgtaway[ndx] = false;
	}

	return processData(ndx);
}
//.................................................................................
int VatLogData::processSrMeasuredTargetStates (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int ndx = sh->unit_id() -1;
	if (printmeSR[ndx])
	{
		srPosition = SrOutput->position_;
		printmeSR[ndx] = false;
		ACE_DEBUG ((LM_DEBUG, "*** Target %d Detected by Surveillance Radar ", sh->unit_id()));
		ACE_DEBUG ((LM_DEBUG, " at time: %f, Distance (%f %f %f)\n", currTime_, srPosition.getX(), srPosition.getY(), srPosition.getZ()));
	}
	return 1;
}

//.................................................................................
int VatLogData::processTrkRadarOnCmd (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int tocUnitID = sh->unit_id();
	int tgtUnitID = TocToTrkRadar->unitID_;
	ACE_DEBUG ((LM_DEBUG, "*** Begin TrkRadar Tracking Target %d ", tgtUnitID));
	ACE_DEBUG((LM_INFO,"TOC Unit ID %d  Received at time: %f\n",tocUnitID,currTime_));
	return 1;
}

//.................................................................................
int VatLogData::doLaunchRequest (Samson_Peer::MessageBase *)
{
	int mslUnitID = mLaunchRequest->unitID_;
	double launchTime = mLaunchRequest->time_;

	ACE_DEBUG ((LM_DEBUG, "*** Launch Request Received by Launcher"));
	ACE_DEBUG((LM_INFO,"Missile UnitID: %d  Received at time: %f\n",mslUnitID, launchTime));
	return 1;
}

//.................................................................................
int VatLogData::processLaunchMissile (Samson_Peer::MessageBase *)
{
	int mslUnitID = mLaunchCmd->unitID_;
	double launchTime = mLaunchCmd->time_;

	prelnch[mslUnitID -1] = false;

	ACE_DEBUG ((LM_DEBUG, "*** Missile %d Away", mslUnitID));
	ACE_DEBUG((LM_INFO,"Received at time: %f\n",launchTime));
	return 1;
}

//.................................................................................
int VatLogData::processTrkRadarMeasuredTargetStates (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int ndx = sh->unit_id() -1;
	if (printmeMFCRTgt[ndx])
	{
		printmeMFCRTgt[ndx] = false;
		ACE_DEBUG ((LM_DEBUG, "*** Target %d Tracking begun by TrkRadar ", sh->unit_id()));
		ACE_DEBUG ((LM_DEBUG, "Received at time: %f\n",currTime_));
   	}
   	return 1;
}
//.................................................................................
int VatLogData::processTrkRadarUplink (Samson_Peer::MessageBase *mb)
{
	const SamsonHeader *sh = mb->get_header();

	int ndx = sh->unit_id() -1;
	if (printmeMFCRMsl[ndx])
	{
		printmeMFCRMsl[ndx] = false;
		ACE_DEBUG ((LM_DEBUG, "*** Missile %d Tracking begun by TrkRadar ", sh->unit_id()));
		ACE_DEBUG ((LM_DEBUG, "Received at time: %f\n",currTime_+0.1));
	}
	return 1;
}

//.................................................................................
int VatLogData::doTargetDestroyed (Samson_Peer::MessageBase *)
{
	int tgtUnitID = mTargetDestroyed->unitID_;
	int ndx = tgtUnitID -1;
	if (printmetgtdst[ndx])
	{
		ACE_DEBUG ((LM_DEBUG, "*** Target %d Destroyed at \n", tgtUnitID, currTime_));
		printmetgtdst[ndx] = false;
		this -> print(ndx);
	}
	return 1;
}

//.................................................................................
int VatLogData::processData (int ndx) //save Target and Missile data to a structure
{
	static int ctr = 0;

	if (tgtdatrcv[ndx] && (msldatrcv[ndx]||prelnch[ndx]))
	{
		dataLogData[ndx].simTime = currTime_;
		if (pSaveDataStart && (iDataCount[ndx] < dataSize)) //write data to memory
		{
			pSaveDataStart[ndx][iDataCount[ndx]++] = dataLogData[ndx];
		}
		tgtdatrcv[ndx] = false;
		msldatrcv[ndx] = false;

#if 0
		int i = iDataCount[ndx]-1;
		ACE_DEBUG((LM_DEBUG,"%d %d=> %f (%f,%f,%f) (%f,%f,%f) %d\n", ndx, i,
			pSaveDataStart[ndx][i].simTime,
			pSaveDataStart[ndx][i].TgtPosition.getX(), pSaveDataStart[ndx][i].TgtPosition.getY(), pSaveDataStart[ndx][i].TgtPosition.getZ(),
			pSaveDataStart[ndx][i].MslPosition.getX(), pSaveDataStart[ndx][i].MslPosition.getY(), pSaveDataStart[ndx][i].MslPosition.getZ(),
			ctr
		));
#endif
		ctr = 0;
	}
	else
		ctr++;


	return 1;
}

//...................................................................................................
//print missile and target data to file
int VatLogData::MonteCarlo_EndRun (Samson_Peer::MessageBase *)
{
	iDataCount[0] = 1999;
	iDataCount[1] = 999;
	iDataCount[2] = 1449;
	const float missileId = 100;
	const float targetId  = 200;
	const float pipId     = 500;

	if (pSaveDataStart)
	{
		for (int ndx = 0; ndx<numberUnitID; ++ndx)
		{
			ofstream *dataLog_out;

			// Create a persistent store.
			char filename[1024];
			sprintf(filename,"data_VAT_%d",ndx);
			dataLog_out = Samson_Peer::SAMSON_OBJMGR::instance()->CreateOutputFile(filename);

			if (dataLog_out->bad ())
			{
				ACE_DEBUG((LM_ERROR,"The output file could not be opened for %d\n", ndx));
				exit (0);
			}
			else
			{
				dataLog_out->precision (10);
				ACE_DEBUG((LM_INFO,"File for VAT output opened for %d. Saving Data.\n", ndx));
				//Implacement of the launcher must be the first in the text files
				//to be used for the VAT. The VAT treats the first data point as
				//its center for reference in Lat, Lon, Alt coordinate system
				//(All other points are NED based off this one LLA coordinate).

				*dataLog_out << "300 0.0 39.25 -118.0 1000.0 0.0 0.0 0.0" << std::endl;
				//sets location of launcher is 300 and gets Lat, Lon, Alt, R,P,Y in degrees
				*dataLog_out << "1100 0.0 50.0 0.0 0.0 0.0 0.0 0.0" << std::endl;
				//sets the location of the command center is 1100 and gets time NED, RPY
				for (int i=0; i<iDataCount[ndx]; i++)
				{
					//Missile is 100 and gets time, NED, RPY
					*dataLog_out << missileId << " " << pSaveDataStart[ndx][i].simTime << " " << pSaveDataStart[ndx][i].MslPosition << " " << pSaveDataStart[ndx][i].MslAttitude << std::endl;
				}

				for (int i=0; i<iDataCount[ndx]; i++)
				{
					//Target is 200 and gets time, NED, RPY
					*dataLog_out << targetId << " " << pSaveDataStart[ndx][i].simTime << " " << pSaveDataStart[ndx][i].TgtPosition << " " << pSaveDataStart[ndx][i].TgtAttitude << std::endl;
				}

				//Radar is 50 and gets model#, time, TrkRadarId# (1 or 2), NED, RPY
				*dataLog_out << "50 0.000000 1 100.0 0.0 0.0 0.0 0.0 0.0" << std::endl;
				*dataLog_out << "50 0.000000 2 -100.0 0.0 0.0 0.0 0.0 0.0" << std::endl;
				//Radar domes (search beams) is 600 and get model#, time, TrkRadarId#, RPY
				//These values are place holders for possible future radar dome data
				*dataLog_out << "600 1.100000 1 0.0 0.0 0.0" << std::endl;
				*dataLog_out << "600 1.100000 2 0.0 0.0 -180" << std::endl;
				*dataLog_out << "600 2.000000 1 0.0 0.0 90" << std::endl;
				*dataLog_out << "600 2.000000 2 0.0 0.0 -90" << std::endl;
				*dataLog_out << "600 5.500000 1 0.0 0.0 180" << std::endl;
				*dataLog_out << "600 5.500000 2 0.0 0.0 0" << std::endl;
				//PIP is 500 and gets time, NED
				int j = iDataCount[ndx] -1;
				*dataLog_out << pipId << " 0.0 " << pSaveDataStart[ndx][j].TgtPosition << std::endl;
				*dataLog_out << pipId << " " << pSaveDataStart[ndx][j].simTime << " " << pSaveDataStart[ndx][j].TgtPosition << std::endl;
				//This is a place holder and is being replaced by the last NED of the target for now
				//         ACE_DEBUG((LM_INFO,"Data saved with %f data points for the missile/target\n",iDataCount));
				//check of how many data point placed in the file for the missile/target
				dataLog_out->close ();
			}
			iDataCount[ndx] = 0;
			delete[] pSaveDataStart[ndx];
		}
	}

	this->vat_timer_.stop ();
	ACE_Time_Value measured;
	this->vat_timer_.elapsed_time (measured);
	double interval_sec = measured.msec () / 1000.0;
	ACE_DEBUG((LM_DEBUG,"Execution time %f\n", interval_sec));

	return 1;
}


//...................................................................................................
void VatLogData::print(int index)
{
	int ndx = index;
   	ACE_DEBUG((LM_INFO,"The Time, Target position when destroyed: %f (%f %f %f)\n",
   		dataLogData[ndx].simTime+0.1, dataLogData[ndx].TgtPosition.getX(),
   		dataLogData[ndx].TgtPosition.getY(), dataLogData[ndx].TgtPosition.getZ()));
}

ACE_FACTORY_DECLARE(ISE,VatLogData)
