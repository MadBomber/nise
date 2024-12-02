////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Tater.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Tater Smith
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

#ifndef _TATER_HPP
#define _TATER_HPP

#include "ISE.h"

#include "PeerTable.h"
#include "XmlObjMessage.h"
#include "AppBase.h"
#include "MessageFunctor.hpp"
#include "Model_ObjMgr.h"
#include "DebugFlag.h"

#include <cmath>
#include <iostream>
#include <vector>

//... boost smart pointers
//#include <boost/scoped_ptr.hpp>

#include <boost/serialization/vector.hpp>

#include "ace/Reactor.h"
#include "ace/Get_Opt.h"
#include "ace/High_Res_Timer.h"


// =========================================================================================
// =========================================================================================
// =========================================================================================
struct TaterMsg:public XmlObjMessage<TaterMsg>
{
	TaterMsg(int size):XmlObjMessage<TaterMsg>("Tater", "Tater Msg"),tater(0),count(0)
	{
		this->payload.reserve(size);
	}

#define ITEMS \
	ITEM(int, tater) \
	ITEM(int, count) \
	ITEM(std::vector<unsigned char>, payload)
#include "messages.inc"
};


// =========================================================================================
// =========================================================================================
// =========================================================================================
class ISE_Export Tater: public Samson_Peer::AppBase
{
public:

	Tater():AppBase(), subscribe_all_taters_(false), payload_size(10)
	{
	}

	~Tater()
	{
		//ACE_DEBUG((LM_DEBUG, "Tater::~Tater() %d called %d\n", this->unit_id_, this->callback_count_));
	}

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	// Called every three seconds until all the Taters have reported in
	int initWaitForAll(void);

	// Received the message
	int passTheTater(Samson_Peer::MessageBase *);

protected:

#define ITEMS \
	ITEM(int,  callback_count_) \
	ITEM(int,  max_taters_) \
	ITEM(int,  max_passes_)
#include "tater_states.inc"

	//boost::scoped_ptr<TaterMsg> msgTater;
	auto_ptr<TaterMsg> msgTater;

	// Elapsed time the module is loaded
	ACE_High_Res_Timer timer_;


	// used only by the first tater
	Samson_Peer::PeerTable peer_table;

	// subscription flag
	bool subscribe_all_taters_;

	// Tater extra payload size
	unsigned int payload_size;

	// ACE Svc Timout handler
	virtual int handle_timeout (const ACE_Time_Value &, const void *arg);

	// timeout processing pointer function
	int (Tater::*timeout_action)(void);
};

ACE_FACTORY_DEFINE(ISE,Tater)

#endif
