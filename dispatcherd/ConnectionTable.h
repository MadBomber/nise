/**
 *	@file ConnectionTable.h
 *
 *  @class ConnectionTable
 *
 *  @brief Table of ConnectionRecords
 *
 *  This is a table of the other peers in the Simulation and how to contact
 *	each of them.
 *
 *	I am using the ACE mapping template, it functions like the STL map class.
 *
 *	What is stored
 *		id:	Key
 *		name:	The human key
 *		ip:		Listen IP
 *		port:	Listen Port
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *

 */

#ifndef ConnectionTable_H
#define ConnectionTable_H

#include "ISE.h"
#include "DispatcherConfig.h"

// STL
#include <map>

// ACE includes
#include "ace/config-all.h"
#include "ace/Singleton.h"
#include "ace/Map_Manager.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"

//....boost spirit parser (used to register XML Keyword)
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

typedef rule<> rule_type;

//....boost smart pointer
#include <boost/shared_ptr.hpp>

// LOCAL includes
#include "ISEExport.h"
#include "ConnectionRecord.h"  //....this is what we store!


namespace Samson_Peer {

// ==========================================================================
class ISE_Export ConnectionTable
{
	public:

		enum State {
			Empty = 0, Populating, Populated, Clearing,
			Initial=Empty, Runtime=Populated
		};

	protected:

		// ===============================================================================
		// = Build a "Map" to store the Simulation Entities in
		std::map<ACE_INT32, ConnectionRecord *> map_;

		// store the available Entities to build connections with

		State state_;
		// The current state of the Table

		boost::shared_ptr<rule_type> mySpiritParseRulePtr;
		// used to parse XML file

		static ACE_INT32 FreeKey;
		// Used for automatic connections, not sure I like this.

	public:

		ConnectionTable () : mySpiritParseRulePtr(new rule_type) {}
		~ConnectionTable();

		int initialize();
		// called by the factory to initialize (and instanciate) this singleton object

		// = Set/get the current state.
		void state (State s) { this->state_ = s; }
		State state (void) { return this->state_; }

		int bind (ConnectionRecord *);
		// Bind the <ConnectionRecord> to the <map_>.

		int unbind (ACE_INT32);
		// Unbind the <ConnectionRecord> to the <map_>.  (not called?)

		ConnectionRecord *find (ACE_INT32);
		// Locate the <ConnectionRecord> with <map_>.

		//.. These methods operate on each record of the table

		const std::string compute_stats(int type);
		// Loop over <ConnectionHandlers> to compute total I/O

		int command_connections (ConnectionHandler **ch);
		// Loop over <Connection_Handlers> looking for Command Connections

		int master_connections (ConnectionHandler **ch);
		// Loop over <Connection_Handlers> looking for Master Connections (incl Command)

		int initiate_connections (void);
		// Initiate all active connections

		int initiate_connection (ConnectionRecord *entity);
		// Initiate a connection


		const std::string status_recv_connections (void);
		const std::string status_recv_connections_xml (void);
		//const std::string tatus_recv_connections_xml (const char* b, const char* e);
		// print status of all RecieveConnectionHandlers

		const std::string status_connections (void);
		const std::string status_connections_xml (void);
		// print status all active connections

		const std::string status_acceptors (void);
		const std::string status_acceptors_xml (void);
		// print status all passive connections

		void close_connections (void);
		// Close all active/passive connections

		void destroy (void);
		// destroy connection handlers, acceptors, ConnectionRecord(s) and unbind all.

		const std::string print_ctable (void);
		const std::string print_ctable_xml (void);
		// Return a print-ready table of information for reporting

		//.. These methods are to operate on a record

		ConnectionHandler *make_connection_handler (ACE_INT32 id);
		// Create a ConnectionHandler

		ConnectionHandler *make_connection_handler (ConnectionRecord *entity);
		// Create a ConnectionHandler

		void insert_connection_handler(ACE_INT32 id, ConnectionHandler *ch);
		// Insert ConnectionHandler in the proper Connection Record

		//.. Interface with Boost Serialization

		static void restore(const char *begin, const char *end);
		// Used to restore the table from boost archive

};


// =======================================================================
// Create a singleton for the application
// Manage this from EventChannel::destroy
typedef ACE_Unmanaged_Singleton<ConnectionTable, ACE_Recursive_Thread_Mutex> CONNECTION_TABLE;

} // namespace

#endif
