/**
 *	@class ModelIdentity
 *
 *	@brief Used to completely identify a Model attached to this Dispatcher
 *
 *	This object is used to ...
 *
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef ModelIdentity_H
#define ModelIdentity_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

#include <string>
#include <sstream>
#include <iomanip>

//....boost serialization
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"

// local includes
#include "ConnectionHandler.h"
#include "auto.h"

namespace Samson_Peer {

class ModelIdentityRecord
{
	public:
		int chid;		//  Channel Handler ID
		unsigned int jid;	//  Job ID
		unsigned int mid;	//  PeerID  , either Model or Service ID
		unsigned int nodeid;	//  NodeID
		unsigned int unitid;	//  Unity ID
		unsigned int statsid;	//  RunStats ID
		int pid;				//  Process ID
		std::string mid_name;	//  Model or Service ID Name  (RDBMS field is 32!!)
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
			& make_nvp("jid"     , jid)
			& make_nvp("mid"     , mid)
			& make_nvp("nodeid"  , nodeid)
			& make_nvp("unitid"  , unitid)
			& make_nvp("statsid" , statsid)
			& make_nvp("pid"     , pid)
			& make_nvp("mid_name", mid_name)
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


/* tags for accessing the corresponding indices of ModelIdentirySet */

struct M_CHID{};
struct M_JID{};
struct M_MID{};
struct M_NAME{};
struct M_UID{};
struct M_SID{};
struct M_NID{};
struct M_PID{};
struct M_CON{};

typedef Samson_Peer::ModelIdentityRecord MODEL_IR;

typedef multi_index_container<
  MODEL_IR,
  indexed_by<
	ordered_unique    <tag<M_CHID>,member<MODEL_IR,int,&MODEL_IR::chid> >,
	ordered_non_unique<tag<M_JID> ,member<MODEL_IR,unsigned int,&MODEL_IR::jid> >,
	ordered_unique    <tag<M_MID> ,member<MODEL_IR,unsigned int,&MODEL_IR::mid> >,
	ordered_non_unique<tag<M_NID> ,member<MODEL_IR,unsigned int,&MODEL_IR::nodeid> >,
	ordered_non_unique<tag<M_UID> ,member<MODEL_IR,unsigned int,&MODEL_IR::unitid> >,
	ordered_non_unique<tag<M_SID> ,member<MODEL_IR,unsigned int,&MODEL_IR::statsid> >,
	ordered_unique    <tag<M_PID> ,member<MODEL_IR,int,&MODEL_IR::pid> >,
	ordered_non_unique<tag<M_NAME>,member<MODEL_IR,std::string,&MODEL_IR::mid_name> >,
	ordered_unique    <tag<M_CON>,member<MODEL_IR,Samson_Peer::ConnectionHandler *,&MODEL_IR::ch> >
 >
> ModelIdentitySet;

namespace Samson_Peer {

class ModelIdentity
{
	public:
		enum State {  Active = 0, Destroyed };

		ModelIdentity();
		~ModelIdentity();

		bool bind (ModelIdentityRecord *e) { return this->map_.insert(*e).second; }
		// Bind the <SamsonIdenty> to the <map_>.

		void unbindCHID(int chid);
		void unbindCH(ConnectionHandler *ch);
		void unbindModelID (ACE_UINT32 id);
		// Remove the ConnectionHandler

		bool findModelID (ACE_UINT32 id, ModelIdentityRecord *entity);
		bool findNodeID  (ACE_UINT32 id, ModelIdentityRecord *entity);
		bool findCHID (ACE_INT32 id, ModelIdentityRecord *entity);
		bool findCH (ConnectionHandler *ch, ModelIdentityRecord *entity);

		ConnectionHandler *getCHfromModelID (ACE_UINT32 id);
		ConnectionHandler *getCHfromCHID (ACE_UINT32 id);

		void destroy (void);
		// destroy the table.

		const std::string report_xml(void);
		const std::string report(void);
		void print (void) { ACE_DEBUG ((LM_DEBUG, "D2M Table\n%s\n", (this->report()).c_str())); }

		typedef ModelIdentitySet::index<M_JID>::type JOBS;
		typedef JOBS::iterator JIT;
		std::pair<JIT,JIT> allRecordsInJob(unsigned int jid) {return map_.get<M_JID>().equal_range(jid);}

		template <class NDX, class ARGTYPE>
		typename ModelIdentitySet::index<NDX>::type::iterator lower_bound(ARGTYPE jid) {return map_.get<NDX>().lower_bound(jid);}

		template <class NDX, class ARGTYPE>
		typename ModelIdentitySet::index<NDX>::type::iterator upper_bound(ARGTYPE jid) {return map_.get<NDX>().upper_bound(jid);}

		ModelIdentitySet::index<M_CHID>::type::iterator begin() {return map_.begin();}

		ModelIdentitySet::index<M_CHID>::type::iterator end() {return map_.end();}

	private:
		ModelIdentitySet map_;
		// store the available Samson Identity Records

		State state_;
		// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from ConnectionTable::destroy
typedef ACE_Unmanaged_Singleton<ModelIdentity, ACE_Recursive_Thread_Mutex> D2M_TABLE;

} // namespace

#endif
