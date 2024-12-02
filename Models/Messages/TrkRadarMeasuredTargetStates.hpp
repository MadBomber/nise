////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TrkRadarMeasuredTargetStates.hpp
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

#ifndef _TRKRADAR_MEASURED_TARGET_STATES_HPP
#define _TRKRADAR_MEASURED_TARGET_STATES_HPP

#include "Vec3.hpp"

#include "ISEExport.h"
#include "XmlObjMessage.h"

//.................................................................................
struct ISE_Export TrkRadarMeasuredTargetStates :  public XmlObjMessage<TrkRadarMeasuredTargetStates>
{
	TrkRadarMeasuredTargetStates (void) : 
		XmlObjMessage<TrkRadarMeasuredTargetStates>(std::string("TRKRADAR_MeasPos"), std::string("TRKRADAR Measured Position")){}

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"
		
};

#endif

