////////////////////////////////////////////////////////////////////////////////
//
// Filename:         CMD_Missile.hpp
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

#ifndef _TARGET_HPP
#define _TARGET_HPP

//#include "ace/Service_Config.h"

#include "ISE.h"
#include "SamsonModel.h"
#include "MessageBase.h"

#include <iostream>

class CMD_Stop;
class CMD_Event;
class CMD_MissileState;
class CMD_TargetState;

namespace Samson_Peer
{
class MessageBase;
}

class ISE_Export CMD_Missile: public Samson_Peer::SamsonModel
{
public:
	
	CMD_Missile();
	~CMD_Missile() {}

	// to get state information
	virtual int info (ACE_TCHAR **info_string, size_t length) const;
	ISE_Export friend ostream& operator<<(ostream& output, const CMD_Missile& p);

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) {return 1;}
	virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *);
	virtual int endSimulation(Samson_Peer::MessageBase *) {return 1;}
	int processTargetInput (Samson_Peer::MessageBase *mb);
	int processStopInput   (Samson_Peer::MessageBase *mb);
	int doMissileDestroyed (Samson_Peer::MessageBase *mb);

protected:
	void print(void);

#define ITEMS \
		ITEM(int,     stop)
#include "model_states.inc"

	CMD_Stop        *mSimStop;
	CMD_Event       *mSimEvent;
	CMD_TargetState *mTgtState;
};

ACE_FACTORY_DEFINE(ISE,CMD_Missile)

#endif
