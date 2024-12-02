///////////////////////////////////////////////////////////////////////////////
//
// Filename:         MissileInitializePos.hpp
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

#ifndef _MISSILE_INITIALIZE_POS_HPP
#define _MISSILE_INITIALIZE_POS_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

struct ISE_Export MissileInitializePos : public XmlObjMessage<MissileInitializePos>
{
	MissileInitializePos (void) : XmlObjMessage<MissileInitializePos>(std::string("MissileInitializePos"), std::string("Missile Initialize Position")),time_(-1.0) {}

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(SamsonMath::EulerAngles,  attitude_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"

};

#endif
