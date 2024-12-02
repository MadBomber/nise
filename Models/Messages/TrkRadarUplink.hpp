////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TrkRadarUplink.hpp
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

#ifndef _TRKRADARUPLINK_HPP
#define _TRKRADARUPLINK_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

#include "Vec3.hpp"

struct ISE_Export TrkRadarUplink :  public XmlObjMessage<TrkRadarUplink>
{
	TrkRadarUplink (void) : XmlObjMessage<TrkRadarUplink>(std::string("TrkRadar_Uplink"), std::string("TrkRadar Uplink")) {}

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"
};

#endif

