////////////////////////////////////////////////////////////////////////////////
//
// Filename:         SrMeasuredTargetStates.hpp
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

#ifndef _MEASUREDTARGETSTATES_HPP
#define _MEASUREDTARGETSTATES_HPP

#include "Vec3.hpp"
#include "ISEExport.h"
#include "XmlObjMessage.h"

//.................................................................................
struct ISE_Export SrMeasuredTargetStates :  public XmlObjMessage<SrMeasuredTargetStates>
{
	SrMeasuredTargetStates (void) : XmlObjMessage<SrMeasuredTargetStates>(std::string("SR_MeasTgtState"), std::string("Surveillance Radar Measured Target")) {}

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"
};

#endif
