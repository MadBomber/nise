////////////////////////////////////////////////////////////////////////////////
//
// Filename:         TrkRadarOnCmd.hpp
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

#ifndef _TRKRADARONCMD_HPP
#define _TRKRADARONCMD_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

struct ISE_Export TrkRadarOnCmd : public XmlObjMessage<TrkRadarOnCmd>
{
	TrkRadarOnCmd (void) : XmlObjMessage<TrkRadarOnCmd>(std::string("TrkRadarOnCmd"), std::string("TRKRADAR On data")) {}

	#define ITEMS \
	ITEM(double,     time_) \
	ITEM(bool,       on_) \
	ITEM(ACE_UINT32, unitID_)
	#include "messages.inc"
};

#endif
