////////////////////////////////////////////////////////////////////////////////
//
// Filename:         SamsonEventLog.cpp
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

#include "ISERelease.h"
#include "ISETrace.h" // first to toggle tracing

#include "SamsonEventLog.hpp"
#include "SamsonHeader.h"
#include "MessageFunctor.hpp"
#include "DebugFlag.h"
#include "Model_ObjMgr.h"
#include <string>
#include <fstream>


//.................................................................................
SamsonEventLog::SamsonEventLog():
	SamsonModel()
{
	Samson_Peer::DebugFlag::instance ()->enable (Samson_Peer::DebugFlag::APB_DEBUG);
}


//.................................................................................
int SamsonEventLog::init(int argc, ACE_TCHAR *argv[])
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::init() called\n"));

	this->timing_.set(10);  // 10Hz

	return this->SamsonModel::init(argc,argv);
}

//...................................................................................................
int SamsonEventLog::fini(void) //print missile and target data to file
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::fini() called\n"));
	return 1;
}

//...................................................................................................
int SamsonEventLog::MonteCarlo_InitCase(Samson_Peer::MessageBase *mb)
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::MonteCarlo_InitCase() called\n"));
	mb->print();
	const SamsonHeader *sh = mb->get_header();
	sh->print();
	return 1;
}

//...................................................................................................
int SamsonEventLog::MonteCarlo_Step(Samson_Peer::MessageBase *mb)
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::MonteCarlo_Step() called\n"));
	mb->print();
	const SamsonHeader *sh = mb->get_header();
	sh->print();
	return 1;
}

//...................................................................................................
int SamsonEventLog::MonteCarlo_EndCase(Samson_Peer::MessageBase *mb)
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::MonteCarlo_EndCase() called\n"));
	mb->print();
	const SamsonHeader *sh = mb->get_header();
	sh->print();
	return 1;
}

//...................................................................................................
int SamsonEventLog::MonteCarlo_EndRun(Samson_Peer::MessageBase *mb)
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::MonteCarlo_EndRun() called\n"));
	mb->print();
	const SamsonHeader *sh = mb->get_header();
	sh->print();
	return 1;
}

//...................................................................................................
int SamsonEventLog::endSimulation(Samson_Peer::MessageBase *mb)
{
	ACE_DEBUG ((LM_DEBUG, "SamsonEventLog::endSimulation() called\n"));
	mb->print();
	const SamsonHeader *sh = mb->get_header();
	sh->print();
	return 1;
}



ACE_FACTORY_DECLARE(ISE,SamsonEventLog)
