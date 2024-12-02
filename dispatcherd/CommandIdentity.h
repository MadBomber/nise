/**
 *	@class CommandIdentity
 *
 *	@brief Used to completely identify another Dispatcher connected to this Dispatcher
 *
 *	This object is used to ...
 *
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef CommandIdentity_H
#define CommandIdentity_H

#include "ISE.h"

#include "ConnectionHandler.h"
#include "DispatcherConfig.h"

#include <string>
#include <sstream>

#include "ace/Service_Config.h"
#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

//....boost serialization
//#include <boost/spirit/core.hpp>
//#include <boost/spirit/utility.hpp>
//#include <boost/spirit/dynamic.hpp>

#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"

namespace Samson_Peer {

class CommandIdentityRecord
{
	public:
		int chid;		//  Channel Handler ID

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


/* tags for accessing the corresponding indices of CommandIdentitySet */

struct C_CHID{};
struct C_CON{};

typedef Samson_Peer::CommandIdentityRecord COMMAND_IR;

typedef multi_index_container<
 COMMAND_IR,
  indexed_by<
	ordered_unique <tag<C_CHID>,member<COMMAND_IR,int,&COMMAND_IR::chid> >,
	ordered_unique <tag<C_CON> ,member<COMMAND_IR,Samson_Peer::ConnectionHandler *,&COMMAND_IR::ch> >
 >
> CommandIdentitySet;

namespace Samson_Peer {

class CommandIdentity
{
	public:
		enum State {  Active = 0, Destroyed };

		CommandIdentity();
		~CommandIdentity();

		bool bind (CommandIdentityRecord *e) { return this->map_.insert(*e).second; }
		// Bind the <SamsonIdenty> to the <map_>.

		void unbindCHID(int chid) { this->map_.get<C_CHID>().erase(chid); }
		void unbindCH(ConnectionHandler * ch) { this->map_.get<C_CON>().erase(ch); }
		// Remove the ConnectionHandler

		bool findCHID (ACE_INT32 id, CommandIdentityRecord *entity);

		ConnectionHandler *getCHfromCHID   (ACE_UINT32 id);

		void destroy (void);
		// destroy the table.

		const std::string report (void);
		const std::string report_xml (void);

	private:

		CommandIdentitySet map_;
		// store the available Samson Identity Records

		State state_;
		// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from ConnectionTable::destroy
typedef ACE_Unmanaged_Singleton<CommandIdentity, ACE_Recursive_Thread_Mutex> D2C_TABLE;


} // namespace

#endif
