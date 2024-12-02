#ifndef _CMDTARGETSTATE_H
#define _CMDTARGETSTATE_H

#include "ISEExport.h"
#include "ObjMessage.h"

//.................................................................................
class ISE_Export CMD_TargetState :  public ObjMessage<CMD_TargetState>
{
	public:
		CMD_TargetState (void) : 
			ObjMessage<CMD_TargetState>(std::string("CMDTargetState"), std::string("Target Truth")) {}
		

	#define ITEMS \
	ITEM(double, x) \
	ITEM(double, y) \
	ITEM(double, vx) \
	ITEM(double, vy)
	#include "messages.inc"

};

#endif
