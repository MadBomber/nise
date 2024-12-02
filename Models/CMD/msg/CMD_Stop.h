#ifndef _CMDSTOP_H
#define _CMDSTOP_H

#include "ISEExport.h"
#include "ObjMessage.h"

//.................................................................................
class ISE_Export CMD_Stop :  public ObjMessage<CMD_Stop>
{
	public:
		CMD_Stop (void) : 
			ObjMessage<CMD_Stop>(std::string("CMDStop"), std::string("Model Stage")) {}
		

	#define ITEMS \
	ITEM(double, t) \
	ITEM(int, stop)
	#include "messages.inc"

};

#endif
