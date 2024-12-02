/*
 * ChannelFilter.cpp
 *
 *  Created on: Jun 8, 2009
 *      Author: lavender
 */


#define ISE_BUILD_DLL

#include "ace/Dynamic_Service.h"

#include "ChannelFilterMgr.h"
#include "LogLocker.h"
#include "DebugFlag.h"


namespace Samson_Peer {




// =====================================================================
ChannelFilterMgr::~ChannelFilterMgr()
{
	ACE_TRACE("ChannelFilterMgr::~ChannelFilterMgr()");
	if ( state_ != Destroyed ) this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~ChannelFilterMgr called.\n"));
#endif

}

// =====================================================================
int ChannelFilterMgr::initialize()
{
	ACE_TRACE("ChannelFilterMgr::initialize");
	this->state_ = Active;
	// this does nothing...yet!
	return 1;
}

// =====================================================================
// This should do NOTHING since all the channels are closed
void ChannelFilterMgr::destroy()
{
	ACE_TRACE("ChannelFilterMgr::destroy");

	if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
	{
		LogLocker log_lock;

  		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) ChannelFilterMgr::destroy (%d filters)\n", this->map_.size()));
	}


	std::map<const std::string, ChannelFilterRecord *>::iterator it;
	for (it= this->map_.begin() ; it != this->map_.end(); it++)
	{
		ChannelFilterRecord *entity = it->second;
		std::string directive = std::string("remove ") + entity->dll_name_;
		ACE_Service_Config::process_directive (directive.c_str());
		this->unbind(entity->dll_name_);
		delete entity;

	}

	// remove the mapping
	this->map_.clear();

	this->state_ = Destroyed;
}

// ==========================================================================
ChannelFilterRecord *ChannelFilterMgr::find(const std::string &key)
{
	std::map<const std::string, ChannelFilterRecord *>::iterator it;
	return ((it=this->map_.find(key))!=this->map_.end()) ? it->second : 0;
}

// ==========================================================================
int ChannelFilterMgr::bind(ChannelFilterRecord *entity)
{

	if (DebugFlag::instance ()->enabled(DebugFlag::FILTER_DEBUG) )
		ACE_DEBUG((LM_DEBUG,
				"(%P|%t) ChannelFilterMgr::bind (%0X) with id= %s -> %0X cnt %d\n", entity,
				entity->dll_name_.c_str(), entity->app_, entity->ref_count));

	std::pair<std::map<std::string, ChannelFilterRecord *>::iterator,bool> result =
			this->map_.insert(std::pair<std::string, ChannelFilterRecord *>(entity->dll_name_,entity));

	if (result.second==false)
	{
		ACE_ERROR_RETURN ((LM_ERROR,
				"(%P|%t) ChannelFilterMgr::bind duplicate dll_name_ (%s), already bound\n",
				entity->dll_name_.c_str()),
		-1);
	}
	return 0;
}

// ==========================================================================
int
ChannelFilterMgr::unbind (const std::string &key)
{
	std::map<const std::string, ChannelFilterRecord *>::iterator it;
	if ((it=this->map_.find(key))!=this->map_.end())
	{
		this->map_.erase(it);
		return 0;
	}
	else
	return -1;
}

// ==========================================================================
FilterBase *
ChannelFilterMgr::load(const std::string &dll_name, int argc, char** argv)
{
	ACE_TRACE("ChannelFilterMgr::load");

	ChannelFilterRecord *record = 0;
	FilterBase *retval = 0;

	// short circuit if found
	if ( (record = this->find(dll_name)) != 0)
	{
		record->ref_count++;

		if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
		{
			LogLocker log_lock;

	  		ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) ChannelFilterMgr::ChannelFilter(%s) -> previously loaded (%d)\n",
				dll_name.c_str(), record->ref_count));
		}

		retval = record->app_;  // previously loaded
	}
	else
	{
		std::string directive = std::string("dynamic ");
		directive += dll_name;
		directive += std::string(" Service_Object * ");
		directive += dll_name;
		directive += std::string(":_make_");
		directive += dll_name;
		directive += std::string("() active \"");
		for (int i=0; i<argc; i++) directive += std::string(argv[i]) +  std::string(" ");
		directive += std::string("\"");

		if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG) )
		{
			LogLocker log_lock;
			ACE_DEBUG((LM_DEBUG,"(%P|%t) ChannelFilter::ChannelFilter() -> %s\n",directive.c_str()));
			//ACE::debug(true);
		}

		ACE_Service_Config::process_directive (directive.c_str());
		int test = ACE_Service_Config::instance ()->find ( dll_name.c_str(), 0, 0);

		if (test != -1)
		{
			ChannelFilterRecord *record = new ChannelFilterRecord();

			record->dll_name_ = dll_name;
			record->app_ = ACE_Dynamic_Service<FilterBase>::instance (dll_name.c_str());
			record->ref_count=1;
			this->bind(record);

			retval = record->app_;  // transfer for the return
			//ACE::debug(false);
		}
	}

	return retval;  //  new load
}

// ==========================================================================
FilterBase *
ChannelFilterMgr::unload(const std::string &dll_name)
{
	ACE_TRACE("ChannelFilterMgr::unload");

	ChannelFilterRecord *working;
	if ( (working = this->find(dll_name)) != 0)
	{
		working->ref_count--;  // decrement the reference counter

		// Unload the DLL and removed the record
		if (working->ref_count == 0)
		{
			//working->app_->fini();

			std::string directive = std::string("remove ") + working->dll_name_;
			ACE_Service_Config::process_directive (directive.c_str());
			this->unbind(working->dll_name_);
			delete working;

			if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
			{
				LogLocker log_lock;

				ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) ChannelFilterMgr::unload ->unloaded(%s)\n",dll_name.c_str()));
			}
		}
		else
		{
			if (DebugFlag::instance ()->enabled (DebugFlag::FILTER_DEBUG))
			{
				LogLocker log_lock;

		  		ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) ChannelFilterMgr::unload ->ref_count decremented %d (%s)\n",
					working->ref_count, dll_name.c_str()));
			}
		}
	}
	else
	{
		LogLocker log_lock;

  		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) ChannelFilterMgr::unload ->not found (%s)\n", dll_name.c_str()));
	}
	return 0;  // TODO debating on this return
}

} // namespace
