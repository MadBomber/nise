#ifndef PEERROUTECACHE_H_
#define PEERROUTECACHE_H_

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Singleton.h"
#include "ace/Recursive_Thread_Mutex.h"

#include <vector>
#include <boost/functional/hash.hpp>

#include "PeerRoute.h"

namespace Samson_Peer {


class PeerRouteRecord
{
	public:

		PeerRouteRecord(unsigned int rid, unsigned int aKey, std::vector<PeerRoute> aRoute):
			theRunID(rid), theKey(aKey), theRoute(aRoute) { }

		unsigned int theRunID;					// Job ID	(indexed)
		unsigned int theKey;					// Peer (pk)
		std::vector<PeerRoute> theRoute;		// Cached Local Route
};

}  // namespace


#include <boost/multi_index_container.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index/identity.hpp>
#include <boost/multi_index/member.hpp>


using boost::multi_index_container;
using namespace boost::multi_index;


/* tags for accessing the corresponding indices of ModelIdentirySet */


struct M_P_R_JID{};
struct M_P_R_KEY{};

typedef Samson_Peer::PeerRouteRecord P_R_REC;

typedef multi_index_container<
P_R_REC,
  indexed_by<
	ordered_unique     <tag<M_P_R_KEY>,  member<P_R_REC,unsigned int,&P_R_REC::theKey> >,
	ordered_non_unique <tag<M_P_R_JID> ,member<P_R_REC,unsigned int,&P_R_REC::theRunID>   >
 >
> PeerRouteRecordSet;



namespace Samson_Peer {

class PeerRouteCache
{
	public:
		enum State {  Active = 0, Destroyed };

		PeerRouteCache(): hit_(0), called_(0), state_(Active) { }
		~PeerRouteCache();

		bool bind (PeerRouteRecord &e);
		// Bind the <SamsonIdenty> to the <map_>.

		void unbindRunID (unsigned int rid);
		// Remove the Job from the Cache

		bool findRouting (const unsigned int id, std::vector<PeerRoute> &route);
		// Locate the Routing Record Set

		void destroy (void);

	private:
		PeerRouteRecordSet map_;
		// store the available Routing Records

		unsigned int hit_;
		unsigned int called_;

		ACE_Recursive_Thread_Mutex mutex_;
		// TODO:  document this

		State state_;
		// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from EventChannel::destroy
// close before the PubSub singleton!
typedef ACE_Unmanaged_Singleton<PeerRouteCache, ACE_Recursive_Thread_Mutex> PEER_ROUTE_SET;

} // namespace

#endif /*PEERROUTECACHE_H_*/
