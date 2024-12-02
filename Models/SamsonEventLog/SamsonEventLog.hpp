////////////////////////////////////////////////////////////////////////////////
//
// Filename:         SamsonEventLog.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:
//
// Author:           Nancy Anderson
//                   Adel Klawitter
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

#ifndef _VAT_LOG_DATA_HPP
#define _VAT_LOG_DATA_HPP


#include "ace/High_Res_Timer.h"

#include "ISEExport.h"
#include "SamsonModel.h"

#include "Ned.hpp"
#include "Vec3.hpp"

//... boost smart pointers
#include <boost/scoped_ptr.hpp>


namespace Samson_Peer { class MessageBase; }

class ISE_Export SamsonEventLog : public Samson_Peer::SamsonModel
{
	public:
		SamsonEventLog();
		~SamsonEventLog(){}

		virtual int init(int argc, ACE_TCHAR *argv[]);
		virtual int fini(void);
		
		virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_Step (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *mb);
		virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *mb);
		virtual int endSimulation (Samson_Peer::MessageBase *mb);
		
	protected:
};

ACE_FACTORY_DEFINE(ISE,SamsonEventLog)


#endif
