#ifndef _IDENTITY_TRACE_H
#define _IDENTITY_TRACE_H

#include "DispatcherConfig.h"

#include <map>

#include "ace/Service_Config.h"
#include "ace/Event_Handler.h"
#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

#include "ISEExport.h"
#include "Peer_Connector.h" // NOTE: not using pointer or reference, so I need include

namespace Samson_Peer {

// Trace Direction
// enum DIRECTION { IN, OUT, BOTH};

// Generic map type.
typedef std::map<int, int> TRACE_MAP;

// ===========================================================================
class ISE_Export IdentityTrace
{
protected:

	TRACE_MAP trace_;

public:

	void insert (int id, int dir)  {
			(this->trace_.find(id) != this->trace_.end()) ?
				this->trace_.erase(id) : this->trace_[id]=dir; }
	void remove (int id) { this->trace_.erase(id); }
	bool trace  (int id) { return this->trace_.find(id) != this->trace_.end(); }
};

// =======================================================================
// Create a singleton

typedef ACE_Unmanaged_Singleton<IdentityTrace, ACE_Recursive_Thread_Mutex> IDENTITY_TRACE;


} // namespace

#endif // _IDENTITY_TRACE_H
