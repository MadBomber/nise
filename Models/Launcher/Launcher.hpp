////////////////////////////////////////////////////////////////////////////////
//
// Filename:         $module$.hpp
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

#ifndef _LAUNCHER_HPP
#define _LAUNCHER_HPP

#include "ISE.h"
#include "SamsonModel.h"

#include "LaunchRequest.hpp"
#include "LaunchCmd.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>
#include <boost/array.hpp>

namespace Samson_Peer
{
class MessageBase;
}

class ISE_Export Launcher : public Samson_Peer::SamsonModel
{
public:
	Launcher();
	~Launcher() {}

	int launchMissile (Samson_Peer::MessageBase *mb);

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step(Samson_Peer::MessageBase *);
	virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) { return 1;}
	virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *) { return 1;}
	virtual int endSimulation(Samson_Peer::MessageBase *) { return 1;}

private:

	boost::scoped_ptr<LaunchRequest> mLaunchRequest;
	boost::scoped_ptr<LaunchCmd> mLaunchCmd;

	typedef boost::array<bool,3> Bool3;
        Bool3 missileLaunched;
};

ACE_FACTORY_DEFINE(ISE,Launcher)

#endif

