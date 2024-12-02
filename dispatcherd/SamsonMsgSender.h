#ifndef SAMSONMSGSENDER_H_
#define SAMSONMSGSENDER_H_

#include "ISE.h"

#include "SamsonHeader.h"
#include "ConnectionHandler.h"

#include "ace/Message_Block.h"


namespace Samson_Peer {

// ===========================================================================
class ISE_Export SamsonMsgSender {
	
public:
	static int sendCtrlMsgToModel (int mdl, unsigned int type, unsigned flag, ConnectionHandler *rh);
	static int sendCtrlMsgToJob (int job, unsigned int type, unsigned flag, ConnectionHandler *rh);
	
private:
	static int publish(const void *msg, size_t len, SamsonHeader *sh, ConnectionHandler *rh);
};

}  // namespace

#endif /*SAMSONMSGSENDER_H_*/
