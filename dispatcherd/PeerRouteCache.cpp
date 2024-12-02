#include "PeerRouteCache.h"
#include "auto.h"
#include "Options.h"
#include "LogLocker.h"

namespace Samson_Peer {


PeerRouteCache::~PeerRouteCache()
{
	ACE_TRACE("PeerRouteCache::~PeerRouteCache()");
	if ( state_ != Destroyed ) this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~PeerRouteCache called.\n"));
#endif

}


void PeerRouteCache::destroy (void)
{
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) PeerRouteCache destoyed.\n"));
#endif
	this->map_.clear();
	this->state_ = Destroyed;
}


bool PeerRouteCache::bind (PeerRouteRecord &e)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	return this->map_.insert(e).second;
}


void PeerRouteCache::unbindRunID (unsigned int rid)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);
	this->map_.get<M_P_R_JID>().erase(rid);

	//if (Options::instance ()->enabled (Options::VERBOSE))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) PeerRouteCache::unbindRunID() (%d) -> hit %d out of %d times, new size %d\n",
			rid, hit_, called_, map_.size ()
		));
	}

}

bool
PeerRouteCache::findRouting (const unsigned int id,
		std::vector<PeerRoute> &route)
{
	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	bool result = false;
	AUTO(ptr,this->map_.get<M_P_R_KEY>().find(id));
	if(ptr != this->map_.get<M_P_R_KEY>().end())
	{
		this->hit_++;
		route = (*ptr).theRoute;
		result = true;
	}
	this->called_++;
	return result;
}



} // namespace
