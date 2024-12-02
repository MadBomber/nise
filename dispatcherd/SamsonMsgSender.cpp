
#define ISE_BUILD_DLL

#include <sstream>

#include "SamsonMsgSender.h"
#include "PubSubDispatch.h"
#include "Service_ObjMgr.h"
#include "Options.h"
#include "DebugFlag.h"

namespace Samson_Peer {


// ===========================================================================
/**
 * This sends a dataless Samson Control Message
 *
 * @param type The control message type @see SimMsgType.h
 * @param flag The control message flags @see SimMsgFlag.h
 */
int
SamsonMsgSender::sendCtrlMsgToModel (int mdl, unsigned int type, unsigned flag, ConnectionHandler *rh)
{
	ACE_SET_BITS (flag, SimMsgFlag::p2p);

	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (0);
	sh->peer_id (0);
	sh->dest_peer_id(mdl);
	sh->message_id (rh->get_handle ());			// NOT USED FOR CONTROL MESSAGES
	sh->app_msg_id (0);
	sh->unit_id (0);
	sh->data_length (0);
	sh->bit_flags(flag);
	sh->type (type);

	//sh->print ();

	return SamsonMsgSender::publish( (const void *) 0, 0, sh, rh);
}

int
SamsonMsgSender::sendCtrlMsgToJob (int job, unsigned int type, unsigned flag, ConnectionHandler *rh)
{
	ACE_SET_BITS (flag, SimMsgFlag::job);

	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (job);
	sh->peer_id (0);
	sh->dest_peer_id(0);
	sh->message_id (rh->get_handle ());			// NOT USED FOR CONTROL MESSAGES
	sh->app_msg_id (0);
	sh->unit_id (0);
	sh->data_length (0);
	sh->bit_flags(flag);
	sh->type (type);

	//sh->print ();

	return SamsonMsgSender::publish( (const void *) 0, 0, sh, rh);
}

// ===========================================================================
/**
 * This takes the header and data in a MessageBlock chain and send it using
 * the associated Peer_Handler
 *
 * @param msg message data to send
 * @param len length of the messages to send
 * @param sh the Samson Header
 * @return the total bytes sent or -1 for failure
 */
int
SamsonMsgSender::publish(const void *msg, size_t len, SamsonHeader *sh, ConnectionHandler *rh)
{
	ACE_TRACE("SamsonMsgSender::publish");

	//.......................................................  Data Processing

	// Allocate a new Message_Block for sending this message
	ACE_Message_Block *data_mb =
		new ACE_Message_Block (
			len,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
			Options::instance ()->locking_strategy ());

	if (data_mb == 0 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SamsonMsgSender::publish() -> Data Messsage_Block Allocation Error\n"), -1);

	// copies the data into the message block and sets the mb length  (Note: this is a deep copy)
	if ( data_mb->copy( (const char *)msg,len) == -1 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SamsonMsgSender::publish() -> Data Copy Error\n"), -1);

	// Debug output
#if 0
	{
		ACE_DEBUG ((LM_DEBUG,
					"(%P|%t)  SamsonMsgSender::publish (CID = %d len= %d Hex =%s)\n",
					sh->connection_id (),
					sh->data_length (),
					sh->gethex ()));
		sh->print ();
	}
#endif


	return PUBSUB_DISPATCH::instance()->process(rh, data_mb, sh);
}

}  // namespace
