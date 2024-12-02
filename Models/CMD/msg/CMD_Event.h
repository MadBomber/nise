#ifndef _CMDEVENT_H
#define _CMDEVENT_H

#include "ISEExport.h"
#include "ObjMessage.h"

//.................................................................................
class ISE_Export CMD_Event :  public ObjMessage<CMD_Event>
{
	public:
		CMD_Event (void) : 
			ObjMessage<CMD_Event>(std::string("CMDEvent"), std::string("CMD Event")) {}
		

	#define ITEMS \
	ITEM(int, te)
	#include "messages.inc"

};

#endif
