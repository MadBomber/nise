/**
 *	@file TranscieverHandler.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL


#include "TransceiverHandler.h"
#include "EventChannel.h"
#include "Options.h"

namespace Samson_Peer
{

// ============================================================================
// ============================================================================
// ============================================================================
TransceiverHandler::TransceiverHandler(ConnectionRecord *const entity) :
	ReceiveHandler(entity), TransmitHandler(entity)
{
	ACE_TRACE("TransceiverHandler::TransceiverHandler");
	this->msg_queue ()->high_water_mark(Options::instance ()->max_queue_size());
}

} // namespace 
