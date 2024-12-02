////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Tater.hpp
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

#ifndef _FRAMED_TATER_HPP
#define _FRAMED_TATER_HPP


#include "ISE.h"

#include "PeerTable.h"
#include "XmlObjMessage.h"
#include "SamsonModel.h"
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
struct FramedTaterMsg:public XmlObjMessage<FramedTaterMsg>
{
	FramedTaterMsg(int size):XmlObjMessage<FramedTaterMsg>("Samson Tater", "Samson Tater Msg"),tater(0)
	{
		this->payload.reserve(size);
	}

#define ITEMS \
	ITEM(int, tater) \
	ITEM(int,cb_count) \
	ITEM(int,fr_count) \
	ITEM(bool,inFrame ) \
	ITEM(std::vector<int>, payload)
#include "messages.inc"
};


// =========================================================================================
// =========================================================================================
// =========================================================================================
class ISE_Export FramedTater: public Samson_Peer::SamsonModel
{
public:

	FramedTater():SamsonModel(), payload_size(10)
	{
	}

	~FramedTater()
	{
		//ACE_DEBUG((LM_DEBUG, "FramedTater::~Tater() %d called %d\n", this->unit_id_, this->callback_count_));
	}

	int passTheTater(Samson_Peer::MessageBase *);

	virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *) {return 1;}
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *);
	virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) {return 1;}
	virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *){return 1;}
	virtual int endSimulation(Samson_Peer::MessageBase *){return 1;}


	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

protected:

#define ITEMS \
	ITEM(int,  callback_count_) \
	ITEM(int,  max_taters_) \
	ITEM(int,  max_passes_)
#include "tater_states.inc"

	auto_ptr<FramedTaterMsg> msgTater;

	// Tater extra payload size
	unsigned int payload_size;


	// Elapsed time  from init to fini
	ACE_High_Res_Timer timer_;

	// used only by the first tater
	Samson_Peer::PeerTable peer_table;

	// timeout handler
	int (FramedTater::*timeout_action)(void);
};

ACE_FACTORY_DEFINE(ISE,FramedTater)

#endif
