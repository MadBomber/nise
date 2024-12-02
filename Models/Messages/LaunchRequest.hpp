////////////////////////////////////////////////////////////////////////////////
//
// Filename:         LaunchRequest.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:      
//
// Author:           Nancy Jo Anderson
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

#ifndef _LAUNCHREQUEST_HPP
#define _LAUNCHREQUEST_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

struct ISE_Export LaunchRequest: public XmlObjMessage<LaunchRequest>
{
	LaunchRequest (void) : XmlObjMessage<LaunchRequest>(std::string("LaunchRequest"), std::string("Missile Launch data")) { }

	#define ITEMS \
	ITEM(double,      time_) \
	ITEM(ACE_UINT32,  unitID_)
	#include "messages.inc"
};

#endif
