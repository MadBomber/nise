////////////////////////////////////////////////////////////////////////////////
//
// Filename:         <%= model_name %>.h
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:      <%= model_desc %>
//
// Author:           <%= ENV['USER'] %>
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

#ifndef _<%= model_name.upcase %>_H
#define _<%= model_name.upcase %>_H

#include "ISE.h"
#include "SamsonModel.h"

// Include IseMessage headers used by this IseModel here
// For Example:
// #include "LaunchRequest.h"
// #include "LaunchCmd.h"

//... using the boost smart pointers
#include <boost/scoped_ptr.hpp>
#include <boost/array.hpp>


namespace Samson_Peer
{
class MessageBase;
}

class ISE_Export <%= model_name %> : public Samson_Peer::SamsonModel
{
public:
	<%= model_name %>();
	~<%= model_name %>() {}

  // Put your private method forwards here
  // For Example:
	// int launchMissile (Samson_Peer::MessageBase *mb);

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step(Samson_Peer::MessageBase *);
	virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) { return 1;}
	virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *) { return 1;}
	virtual int endSimulation(Samson_Peer::MessageBase *) { return 1;}

private:

  // Your private parts go here


#include "model_states.inc"

};

ACE_FACTORY_DEFINE(ISE,<%= model_name %>)

#endif


