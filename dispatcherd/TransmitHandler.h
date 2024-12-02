#ifndef _TRANSMIT_HANDLER_H
#define _TRANSMIT_HANDLER_H

#include "ISE.h"

#include "ConnectionHandler.h"

namespace Samson_Peer {

// forward declaration
class Eventheader;

class ISE_Export TransmitHandler : public virtual ConnectionHandler
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
	TransmitHandler (ConnectionRecord * const);

	virtual int put (ACE_Message_Block *event, ACE_Time_Value * = 0);
	/// Send an event to a Consumer (may be queued if necessary).

	virtual int put (ACE_Message_Block *event, EventHeader *eh);
	// new main entry!

protected:
	virtual int handle_output (ACE_HANDLE);
	// Finish sending event when flow control conditions abate.

	int nonblk_put (ACE_Message_Block *mb);
	// Perform a non-blocking put().

	ACE_Message_Block *consolidate(ACE_Message_Block *event);
	// consolodate the message block chain!
};

} // namespace

#endif  // _TRANSMIT_HANDLER_H

