/*
 * Filter.h
 *
 *  Created on: Jun 8, 2009
 *      Author: lavender
 */

#ifndef CH_FILTER_H_
#define CH_FILTER_H_

#include "ISE.h"

#include <string>
#include <map>

#include "EventHeaderFactory.h"
#include "FilterBase.h"

#include "ace/ACE.h"
#include "ace/SString.h"
#include "ace/DLL.h"
#include "ace/DLL_Manager.h"
#include "ace/Auto_Ptr.h"
#include "ace/Message_Block.h"
#include "ace/Map_Manager.h"
#include "ace/Synch.h"
#include "ace/High_Res_Timer.h"

#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"


namespace Samson_Peer {

struct ChannelFilterRecord
{
	std::string dll_name_;
	FilterBase *app_;
	unsigned int ref_count;
};

// ===========================================================================
class ISE_Export ChannelFilterMgr
{
	// = TITLE
	//    Define a generic Connection Handler Filter.
	//
	// = DESCRIPTION
	//

	public:

		enum State {  Active = 0, Destroyed };

		ChannelFilterMgr () : state_(Active) {}
		~ChannelFilterMgr();

		int initialize();
		// called by the factory to initialize (and instantiate) this singleton object

		FilterBase * load (const std::string &fname, int argc=0, char** argv=0);
		// load a filter dll

		FilterBase * unload(const std::string &fname);
		// unload a filter dll

		ChannelFilterRecord *find (const std::string &);
		// Locate the <ChannelFilterRecord> with <map_>.

		void destroy (void);
		// destroy ChannelFilterRecord(s) and unbind all.

	protected:

		int bind (ChannelFilterRecord *);
		// Add the <ChannelFilterRecord> to the <map_>.

		int unbind (const std::string &);
		// Remove the <ChannelFilterRecord> from the <map_>.

		std::map<const std::string, ChannelFilterRecord *> map_;

		State state_;
		// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from EventChannel::destroy
typedef ACE_Unmanaged_Singleton<ChannelFilterMgr, ACE_Recursive_Thread_Mutex> CH_FILTER_MGR;

} // namespace


#endif /* FILTER_H_ */
