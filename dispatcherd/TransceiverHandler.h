#ifndef _TRANSCEIVER_HANDLER_H
#define _TRANSCEIVER_HANDLER_H

#include "ISE.h"

#include "ReceiveHandler.h"
#include "TransmitHandler.h"

namespace Samson_Peer
{

// ==========================================================================
class ISE_Export TransceiverHandler : public ReceiveHandler, public TransmitHandler
{
	// = TITLE
	//     Handles transmission of events to Consumers.
	//
	// = DESCRIPTION
	//     Performs queueing and error checking.  Intended to run
	//     reactively, i.e., in one thread of control using a Reactor
	//     for demuxing and dispatching.  Also uses a Reactor to handle
	//     flow controlled output connections.
public:
	// = Initialization method.
	TransceiverHandler (ConnectionRecord * const);
};

} // namespace

#endif  // _TRANSCEIVER_HANDLER_H
