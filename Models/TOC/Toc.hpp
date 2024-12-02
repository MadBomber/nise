////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Toc.hpp
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

#ifndef _TOC_HPP
#define _TOC_HPP

#include "ISE.h"

#include "SamsonModel.h"
#include "Vec3.hpp"

#include "SrMeasuredTargetStates.hpp"
#include "TrkRadarOnCmd.hpp"
#include "TrkRadarMeasuredTargetStates.hpp"
#include "LaunchRequest.hpp"
#include "TargetDestroyed.hpp"

namespace Samson_Peer { class MessageBase; }

class ISE_Export TOC: public Samson_Peer::SamsonModel
{
	public:
		TOC():SamsonModel(){}
		~TOC(){}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);

		int processTrkRadarInputToc (Samson_Peer::MessageBase *mb);
		int processSrInput (Samson_Peer::MessageBase *mb);

		virtual int MonteCarlo_InitCase(Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step(Samson_Peer::MessageBase *) { if ( this->save_state_ ) toDB("TOC"); return 1; }
		virtual int MonteCarlo_EndCase(Samson_Peer::MessageBase *) { return 1; }
		virtual int MonteCarlo_EndRun(Samson_Peer::MessageBase *) { return 1; }
		virtual int endSimulation(Samson_Peer::MessageBase *) { return 1; }

	protected:
	
		//SamsonMath::Vec3<double> position; // TODO all positions should be changed Ned and not Vec3<double>

		SrMeasuredTargetStates *mTgtSrvMeasured;
		TrkRadarMeasuredTargetStates *mTgtTrkMeasured;

		TrkRadarOnCmd *mRadarOn;
		LaunchRequest *mLaunchRequest;
		TargetDestroyed *mTocEndEngage;

		typedef boost::array<bool,3> Bool3;
	
		int    tocState;
		double mfcrRange;
		double mfcrOnTime;
		Bool3  mfcrOn;
		Bool3  launch;
		Bool3  tgtdest;
		double launchRange; 
};

ACE_FACTORY_DEFINE(ISE,TOC)

#endif

