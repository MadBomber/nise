#ifndef XMLPARSER_H
#define XMLPARSER_H

#include "ISE.h"

#include "DispatcherConfig.h"

// std includes
#include <list>

// ACE includes
#include "ace/Message_Block.h"
#include "ace/Singleton.h"
#include "ace/Recursive_Thread_Mutex.h"
#include "ace/Null_Mutex.h"

// #define BOOST_SPIRIT_DEBUG
#include <boost/spirit/include/classic_spirit.hpp>
#include <boost/spirit/include/classic_dynamic.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/xml_iarchive.hpp>

//....boost smart pointer
#include <boost/shared_ptr.hpp>

// local includes
#include "ISEExport.h"

typedef rule<> rule_type;
typedef boost::shared_ptr<rule_type>  shared_rule_ptr;

class EventHeader; // NOTE: not a member of the Samson_Peer namespace

namespace Samson_Peer {

class ConnectionHandler;

class ISE_Export XMLParser
{
	public:

		XMLParser();
		// Constructor

		~XMLParser();
		// Destructor

		int initialize(void);
		// Initialize the Application Singleton

		int process (ConnectionHandler *, ACE_Message_Block *, EventHeader *);

		int process(const char *theData);
		// Primary Application Interface for parsing a C string

		int fprocess(const char *theFile);
		// Primary Application Interface for parsing a file

		void print_parsers() {};
		// This will print a HUMAN readable list

		void register_parser (shared_rule_ptr);

		//void remove_parser (char *theName)
		//{
			//dirty = true;
			//orRules.push_back(theRule);
		//}

	private :

		bool dirty;
		//  Rules have changed

		std::list<shared_rule_ptr> orRules;
		// The registered rules to be "Or'd

		stored_rule<> registered_parsers;
		// The combined rule set
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from DispatcherFactory::fini
typedef ACE_Unmanaged_Singleton<XMLParser, ACE_Recursive_Thread_Mutex> XML_PARSER;

} // namespace

#endif
