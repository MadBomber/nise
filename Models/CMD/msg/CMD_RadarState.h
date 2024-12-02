#ifndef _CMDRADARSTATE_H
#define _CMDRADARSTATE_H

#include "ISEExport.h"
#include "ObjMessage.h"

//.................................................................................
class ISE_Export CMD_RadarState :  public ObjMessage<CMD_RadarState>
{
	public:
		CMD_RadarState (void) : 
			ObjMessage<CMD_RadarState>(std::string("CMDRadarState"), std::string("Radar Truth")) {}
		

	#define ITEMS \
	ITEM(int, stop)
	#include "messages.inc"

};

#endif
