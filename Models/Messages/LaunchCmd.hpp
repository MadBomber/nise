////////////////////////////////////////////////////////////////////////////////
//
// Filename:         LaunchCmd.hpp
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

#ifndef _LAUNCHCMD_HPP
#define _LAUNCHCMD_HPP

#include "ISEExport.h"
#include "XmlObjMessage.h"

struct ISE_Export LaunchCmd : public XmlObjMessage<LaunchCmd>
{
	LaunchCmd (void) :XmlObjMessage<LaunchCmd>(std::string("LaunchCmd"), std::string("Missile Launch data")) {}
	  
	#define ITEMS \
	ITEM(double,      time_) \
	ITEM(ACE_UINT32,  unitID_)
	#include "messages.inc"

};

#endif


