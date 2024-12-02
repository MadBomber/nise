/**
 *	@file SubscriptionCache.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef SUBSCRIPTIONCACHE_
#define SUBSCRIPTIONCACHE_

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Singleton.h"
#include "ace/Recursive_Thread_Mutex.h"

#include <vector>
#include <boost/functional/hash.hpp>

#include "PeerRoute.h"

namespace Samson_Peer {

class SubscriptionRecordKey
{
	public:
		unsigned int msg_id;
		unsigned int unitID;

		SubscriptionRecordKey(): msg_id(0), unitID(0) {}
		SubscriptionRecordKey(unsigned int msg,unsigned int uid): msg_id(msg), unitID(uid) {}

		bool operator==  (const SubscriptionRecordKey &compare) const
		{
			return msg_id==compare.msg_id  && unitID==compare.unitID;
		}

		friend size_t hash_value(const Samson_Peer::SubscriptionRecordKey &val)
		{
			size_t seed = 0;
			boost::hash_combine(seed, val.msg_id);
			boost::hash_combine(seed, val.unitID);
			return seed;
		}
};


class SubscriptionRecord
{
	public:

		SubscriptionRecord(unsigned int jid, SubscriptionRecordKey aKey, std::vector<PeerRoute> aLocal, std::vector<unsigned int> aRemote):
			theJobID(jid), theKey(aKey), theLocal(aLocal), theRemote(aRemote) { }

		unsigned int theJobID;					//  Job ID	(indexed)
		SubscriptionRecordKey theKey;			//  Msg/UID (pk)
		std::vector<PeerRoute> theLocal;		// Cached Local Route
		std::vector<unsigned int> theRemote; 	// Cached Remote Route
};

}  // namespace



#include <boost/multi_index_container.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index/identity.hpp>
#include <boost/multi_index/member.hpp>
#include <boost/multi_index/hashed_index.hpp>


using boost::multi_index_container;
using namespace boost::multi_index;


/* tags for accessing the corresponding indices of ModelIdentirySet */


struct M_C_JID{};
struct M_C_SK{};

typedef Samson_Peer::SubscriptionRecordKey SUB_REC_KEY;
typedef Samson_Peer::SubscriptionRecord SUB_REC;

typedef multi_index_container<
  SUB_REC,
  indexed_by<
	//ordered_unique     <tag<M_C_SK>,  member<SUB_REC,SUB_REC_KEY,&SUB_REC::theKey> >,
	hashed_unique     <tag<M_C_SK>,  member<SUB_REC,SUB_REC_KEY,&SUB_REC::theKey> >,
	ordered_non_unique <tag<M_C_JID> ,member<SUB_REC,unsigned int,&SUB_REC::theJobID>   >
 >
> SubscriptionRecordSet;



namespace Samson_Peer {

class SubscriptionCache
{
	public:
		SubscriptionCache(): hit_(0), called_(0) { }
		~SubscriptionCache();

		bool bind (SubscriptionRecord &e);
		// Bind the <SamsonIdenty> to the <map_>.

		void unbindRunID (unsigned int rid);
		// Remove the Job from the Cache

		void unbindKey (const SubscriptionRecordKey &id);
		// Remove the subscription

		bool findRouting (const SubscriptionRecordKey &id, std::vector<PeerRoute> &local, std::vector<unsigned int> &remote);
		// Locate the Routing Record Set

		void destroy (void);
		// void destroy (void) { this->map_.clear(); }
		// destroy the table.

	private:
		SubscriptionRecordSet map_;
		// store the available Routing Records

		unsigned int hit_;
		unsigned int called_;

		ACE_Recursive_Thread_Mutex mutex_;
		// TODO:  document this
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from DispatcherFactory::fini
typedef ACE_Unmanaged_Singleton<SubscriptionCache, ACE_Recursive_Thread_Mutex> SUBSCR_SET;

} // namespace


#endif /*SUBSCRIPTIONCACHE_*/
