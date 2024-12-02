///////////////////////////////////////////////////////////////////////////////
//
// Filename:         MissileDownlink.hpp
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

#ifndef _MISSILEDOWNLINK_HPP
#define _MISSILEDOWNLINK_HPP

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "ISEExport.h"
#include "XmlObjMessage.h"

struct ISE_Export MyMissileDownlink : public XmlObjMessage<MyMissileDownlink> 
{
	MyMissileDownlink():XmlObjMessage<MyMissileDownlink>(std::string("MyMissileDownlink"), std::string("Missile Downlink")),time_(-1.0) {}

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(SamsonMath::EulerAngles,  attitude_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"

};
#endif
