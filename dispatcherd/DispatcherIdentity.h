/**
 *	@class DispatcherIdentity
 *
 *	@brief Used to completely identify another Dispatcher connected to this Dispatcher
 *
 *	This object is used to ...
 *
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef DispatcherIdentity_H
#define DispatcherIdentity_H

#include "ISE.h"

#include "DispatcherConfig.h"
#include "ConnectionHandler.h"

#include <string>
#include <sstream>

#include "ace/Service_Config.h"
#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

//....boost serialization
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"


namespace Samson_Peer {

class DispatcherIdentityRecord
{
	public:
		int chid;		//  Channel Handler ID
		unsigned int peer;	//  PeerID
		unsigned int node;	//  NodeID
		ConnectionHandler *ch;	//  Pointer to a Connection Handler

		void print(std::stringstream &my_report) const;

		template<class Archive>
		void serialize(Archive & ar, const unsigned int /* file_version */)
		{
		  std::ostringstream os;
		  os<<std::hex<<ch;
		  std::string ch_str(os.str());
		  using boost::serialization::make_nvp;
			ar
			& make_nvp("chid"    , chid)
			& make_nvp("peer"    , peer)
			& make_nvp("node"    , node)
			& make_nvp("ch"      , ch_str)
			;
		}
};

}  // namespace

#include <boost/multi_index_container.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index/identity.hpp>
#include <boost/multi_index/member.hpp>

using boost::multi_index_container;
using namespace boost::multi_index;


/* tags for accessing the corresponding indices of DispatcherIdentitySet */

struct D_CHID{};
struct D_PID{};
struct D_NID{};
struct D_CON{};

typedef Samson_Peer::DispatcherIdentityRecord DISPATCHER_IR;

typedef multi_index_container<
  DISPATCHER_IR,
  indexed_by<
	ordered_unique <tag<D_CHID>,member<DISPATCHER_IR,int,&DISPATCHER_IR::chid> >,
	ordered_unique <tag<D_PID> ,member<DISPATCHER_IR,unsigned int,&DISPATCHER_IR::peer> >,
	ordered_unique <tag<D_NID> ,member<DISPATCHER_IR,unsigned int,&DISPATCHER_IR::node> >,
	ordered_unique <tag<D_CON> ,member<DISPATCHER_IR,Samson_Peer::ConnectionHandler *,&DISPATCHER_IR::ch> >
 >
> DispatcherIdentitySet;

namespace Samson_Peer {

class DispatcherIdentity
{
	public:

		enum State {  Active = 0, Destroyed };

		DispatcherIdentity();
		~DispatcherIdentity();

		bool bind (DispatcherIdentityRecord *e) { return this->map_.insert(*e).second; }
		// Bind the <SamsonIdenty> to the <map_>.

		void unbindCHID(int chid) { this->map_.get<D_CHID>().erase(chid); }
		void unbindCH(ConnectionHandler *ch) { this->map_.get<D_CON>().erase(ch); }
		// Remove the Connection Handler

		bool findPeerID (ACE_UINT32 id, DispatcherIdentityRecord *entity);
		bool findNodeID  (ACE_UINT32 id, DispatcherIdentityRecord *entity);
		bool findCHID (ACE_INT32 id, DispatcherIdentityRecord *entity);

		ConnectionHandler *getCHfromPeerID (ACE_UINT32 id);
		ConnectionHandler *getCHfromNodeID (ACE_UINT32 id);
		ConnectionHandler *getCHfromCHID   (ACE_UINT32 id);

		void destroy (void);
		// destroy the table.

		const std::string report (void);
		const std::string report_xml (void);
		void print (void) { ACE_DEBUG ((LM_DEBUG, "D2D Table\n%s\n", (this->report()).c_str())); }

	private:

		DispatcherIdentitySet map_;
		// store the available Samson Identity Records

		State state_;
		// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from ConnectionTable::destroy
typedef ACE_Unmanaged_Singleton<DispatcherIdentity, ACE_Recursive_Thread_Mutex> D2D_TABLE;

} // namespace

#endif
