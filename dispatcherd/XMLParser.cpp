#define ISE_BUILD_DLL

// std-lib includes
#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <list>
using namespace std;

//... ACE includes
#include "ace/Log_Msg.h"

//... Local includes
#include "XMLParser.h"
#include "Options.h"
#include "ConnectionHandler.h"
#include "CommandParser.h"
#include "EventHeader.h"
#include "DebugFlag.h"

#include "boost/throw_exception.hpp"

// ===
namespace Samson_Peer {

//............................................................................
XMLParser::XMLParser()
{
	ACE_TRACE("XMLParser::XMLParser");
	dirty=true;
}

//............................................................................
XMLParser::~XMLParser()
{
	ACE_TRACE("XMLParser::~XMLParser");
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~XMLParser called.\n"));
#endif
}

//............................................................................
int XMLParser::initialize()
{
	ACE_TRACE("XMLParser::initialize");
	return 1;  // used in the DispatchFactory to initialize XMLParser
}



//............................................................................
// must return a 0 for success to continue events
int XMLParser::process (
	ConnectionHandler *rh,  // really a TranceiverHandler
	ACE_Message_Block *event,
	EventHeader *
)
{
	const char *buf = event->base();
	// ssize_t n = event->length();  // not sure why I don't need this?

	// Set the connection handler for processing
	COMMAND_PARSER::instance ()->set_connection_handler (rh);

	// relying on this being a null terminated string
	int result = this->process(buf);

	// unset the connection handler
	 COMMAND_PARSER::instance ()->set_connection_handler (0);

	return result;
}

//............................................................................
// must return a 0 for success
int XMLParser::process (const char *buf)
{
	if ( this->dirty )
	{
		int count = 0;
		list<shared_rule_ptr>::iterator i;

		registered_parsers = space_p;  // clears out the store???

		for(i=orRules.begin(); i != orRules.end(); ++i)
		{
			++count;
			registered_parsers = registered_parsers.copy() | **i;
		}

		//registered_parsers = registered_parsers.copy() | space_p;
		registered_parsers = *(registered_parsers.copy());

		dirty = false;

		if (DebugFlag::instance ()->enabled (DebugFlag::OBJ_DEBUG))
			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) XMLParser::process -> Number of Tags Registered %d\n",count));
	}

#if 0
	if (DebugFlag::instance ()->enabled (DebugFlag::OBJ_DEBUG))
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) XMLParser::process -> Buffer \n---\n%s\n---\n",buff));
#endif


	try {
		rule<> xmlParse  = *(anychar_p-'<') >> registered_parsers;
		parse(buf, xmlParse);
	}

	catch( boost::archive::archive_exception &e )
	{
		ACE_DEBUG ((LM_ERROR,
			"(%P|%t) XMLParser::process error -> \n%s\n%s\n",e.what(),buf));
	}
	catch(std::exception &e)
	{
		ACE_DEBUG ((LM_ERROR,
			"(%P|%t) XMLParser::process error -> \n%s\n%s\n",e.what(),buf));
		return -1;
	}
	// TODO  how to catch/report/process parsing errors?


	return 0; // success!
}

//............................................................................
int XMLParser::fprocess (const char *theFile)
{
	ifstream ifs(theFile);
	assert(ifs.good());
	stringstream buffer;
	buffer << ifs.rdbuf();

	if (DebugFlag::instance ()->enabled (DebugFlag::OBJ_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) XMLParser::fprocess(%s)\n",theFile));
		//ACE_DEBUG ((LM_DEBUG,
		//	"---------------------\n%s\n---------------\n",buffer.str().c_str()));

	}

	return process (buffer.str().c_str());
}

//............................................................................
void XMLParser::register_parser (shared_rule_ptr theRule)
{
	orRules.push_back(theRule);
	dirty = true;

	if (DebugFlag::instance ()->enabled (DebugFlag::OBJ_DEBUG))
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) XMLParser::register_parser -> Parser Registered\n"));
}

} // namespace
