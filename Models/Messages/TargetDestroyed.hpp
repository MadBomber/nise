////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TargetDestroyed.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Samson
//
// System Name:      Simulation
//
// Description:      
//
// Author:           Adel Klawitter
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

#ifndef _TARGET_DESTROYED_HPP
#define _TARGET_DESTROYED_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

struct ISE_Export TargetDestroyed : public XmlObjMessage<TargetDestroyed> 
{
	TargetDestroyed (void) : XmlObjMessage<TargetDestroyed>(std::string("TargetDestroyed"), std::string("Target Destroyed End Engagement")) {}

	#define ITEMS \
	ITEM(double,     time_) \
	ITEM(bool,       state_) \
	ITEM(ACE_UINT32, unitID_)
	#include "messages.inc"
};

#endif
