#include "SubscriptionCache.h"
#include "auto.h"
#include "Options.h"
#include "LogLocker.h"

namespace Samson_Peer {

SubscriptionCache::~SubscriptionCache()
{
	this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~SubscriptionCache called.\n"));
#endif
}


void SubscriptionCache::destroy (void)
{
	this->map_.clear();
}


bool SubscriptionCache::bind (SubscriptionRecord &e)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	return this->map_.insert(e).second;
}


void SubscriptionCache::unbindRunID (unsigned int rid)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	this->map_.get<M_C_JID>().erase(rid);

	if (Options::instance ()->enabled (Options::VERBOSE))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) SubscriptionCache::unbindRunID(%d) -> hit %d out of %d times, new size %d\n",
			rid, hit_, called_, map_.size ()
		));
	}

}

void SubscriptionCache::unbindKey (const SubscriptionRecordKey &id)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	this->map_.get<M_C_SK>().erase(id);

	//if (Options::instance ()->enabled (Options::VERBOSE))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) SubscriptionCache::unbindKey(%d-%d)\n",
			id.msg_id, id.unitID
		));
	}

}


bool
SubscriptionCache::findRouting (const SubscriptionRecordKey &id,
		std::vector<PeerRoute> &local, std::vector<unsigned int> &remote)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	bool result = false;
	AUTO(ptr,this->map_.get<M_C_SK>().find(id));
	if(ptr != this->map_.get<M_C_SK>().end())
	{
		this->hit_++;
		local = (*ptr).theLocal;
		remote = (*ptr).theRemote;
		result = true;
	}
	this->called_++;
	return result;
}



} // namespace
