////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Sr.hpp
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

#ifndef _SR_HPP
#define _SR_HPP

#include "ISE.h"

#include "SamsonModel.h"

#include "TruthTargetStates.hpp"
#include "SrMeasuredTargetStates.hpp"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

namespace Samson_Peer
{
class MessageBase;
}

//................................................................
class ISE_Export Sr : public Samson_Peer::SamsonModel
{
public:
	Sr():SamsonModel()
	{}
	~Sr()
	{}

	virtual int init(int argc, ACE_TCHAR *argv[]);
	virtual int fini(void);

	virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
	virtual int MonteCarlo_Step (Samson_Peer::MessageBase *)
	{	if ( this->save_state_ ) toDB("Sr"); return 1;}
	virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *)
	{	return 1;}
	virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *)
	{	return 1;}
	virtual int endSimulation (Samson_Peer::MessageBase *)
	{	return 1;}

	int processTargetInput (Samson_Peer::MessageBase *mb);

private:

	TruthTargetStates *mTgtTruth;
	SrMeasuredTargetStates *mTgtMeasured;

#define ITEMS \
		ITEM(double, blindZone) \
	
#include "model_states.inc"

};

ACE_FACTORY_DEFINE(ISE,Sr)

#endif

