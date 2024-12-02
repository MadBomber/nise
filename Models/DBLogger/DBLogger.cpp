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

#include "DBLogger.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "Model_ObjMgr.h"
#include "mysql.h"
#include <string>
#include <fstream>

#include <boost/regex.hpp>
#include <boost/typeof/typeof.hpp>

int regex_delimit(const char* string, boost::regex expression, std::string* delimited_string);

//.................................................................................
template <class T>
struct toDB_Callback:public Functor
{
  toDB_Callback(T* obj):obj(obj){}
  int operator()(Samson_Peer::MessageBase *) const { obj->toDB(); return 0; }
  Functor *clone() const { return new toDB_Callback(*this); };
  T* obj;
};

template <class T>
toDB_Callback<T>* makeCallback(T* obj)
{
  static toDB_Callback<T> cb(obj);
  cb=toDB_Callback<T>(obj);
  return &cb;
}

//.................................................................................
int DBLogger::init(int argc, ACE_TCHAR *argv[])
{
	ACE_UNUSED_ARG(argc);
	ACE_UNUSED_ARG(argv);

	#define SUBSCRIBE(VAR) \
	  VAR = new BOOST_TYPEOF(*VAR); \
    ACE_DEBUG ((LM_DEBUG, "CALLBACK OBJ: %x\n", VAR )); \
	  VAR->subscribe(makeCallback(VAR),0);

	SUBSCRIBE(MissileToTrkRadarOutput)
	SUBSCRIBE(mTargetState)
	SUBSCRIBE(cmdTgtState)
#if 1
	SUBSCRIBE(mLaunchCmd)
	SUBSCRIBE(mTargetDestroyed)
	SUBSCRIBE(TocToTrkRadar)
	SUBSCRIBE(TrkRadarToToc)
	SUBSCRIBE(SrOutput)
	SUBSCRIBE(mLaunchRequest)
	SUBSCRIBE(TrkRadarInputMissile)
	SUBSCRIBE(MissileToVat)
	SUBSCRIBE(mLLATruth)
#endif

	this->timing_.set(0);

	return this->SamsonModel::init(argc,argv);
}

//...................................................................................................
int DBLogger::fini(void) //print missile and target data to file
{
	delete mTargetState;
	delete cmdTgtState;
	delete MissileToTrkRadarOutput;
	delete mLaunchCmd;
	delete mTargetDestroyed;
	delete TocToTrkRadar;
	delete TrkRadarToToc;
	delete SrOutput;
	delete mLaunchRequest;
	delete TrkRadarInputMissile;
	delete MissileToVat;
	return 1;
}

//...................................................................................................
int DBLogger::MonteCarlo_InitCase(Samson_Peer::MessageBase *)
{
  return 1;
}

//...................................................................................................
//print missile and target data to file
int DBLogger::MonteCarlo_EndRun (Samson_Peer::MessageBase *)
{
  return 1;
}

ACE_FACTORY_DECLARE(ISE,DBLogger)
