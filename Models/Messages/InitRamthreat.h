/**
 *	@file InitRamthreat.h
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef _INITRAMTHREAT_H
#define _INITRAMTHREAT_H

#include <string>

#include "ISEExport.h"
#include "XmlObjMessage.h"
#include "Coord.h"


struct ISE_Export InitRamthreat : public XmlObjMessage<InitRamthreat>
{
	InitRamthreat (void) : XmlObjMessage<InitRamthreat>(std::string("InitRamthreat"), std::string("Initialize Ramgen Threat")) {}

	#define ITEMS \
	ITEM(std::string,	traj_file_) \
	ITEM(double,		lat_origin_degrees_) \
	ITEM(double,		lon_origin_degrees_) \
	ITEM(unsigned int,	launch_frame_) \
	ITEM(double,		heading_degrees_)
	#include "messages.inc"

};

#endif
