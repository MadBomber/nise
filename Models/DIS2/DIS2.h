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

#include <vector>
#include "WayPoint.h"
#include "DeltaTimeStats.h"

// UDP Broadcast
#include "ace/SOCK_Dgram_Bcast.h"
#include "ace/High_Res_Timer.h"

//....boost smart pointer
#include <boost/shared_ptr.hpp>


#include "Ned.hpp"
#include "Vec3.hpp"


namespace Samson_Peer { class MessageBase; }

class ISE_Export DIS2 : public Samson_Peer::SamsonModel
{
public:
	DIS2():SamsonModel() {}
	~DIS2() {}

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *) { return 1;}
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *);
	virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1;}
	virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) {return 1;}

private:
	int processToDIS (Samson_Peer::MessageBase *, WayPoint &, bool);

	ACE_SOCK_Dgram_Bcast dis_socket;
	
	std::vector<WayPoint> path_;
		
	// timer to track start of frames
	ACE_High_Res_Timer frame_timer_;
	
	// Collect timer Stats
	DeltaTimeStats schedule_stats_;
	
	double avg_event;
	int n_event_samples;

};

ACE_FACTORY_DEFINE(ISE,DIS2)


#endif
