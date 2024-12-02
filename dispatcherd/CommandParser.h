/**
 *	@file CommandHandler.h
 *
 *	@class CommandHandler
 *
 *	@brief Process Commands
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef COMMAND_PARSER_H
#define COMMAND_PARSER_H

#include "ISE.h"

#include "DispatcherConfig.h"

// ACE includes
#include "ace/config-all.h"
#include "ace/Singleton.h"
#include "ace/Map_Manager.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"
#include "ace/Message_Block.h"


//....boost spirit parser (used to register XML Keyword)
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

typedef rule<> rule_type;

//....boost smart pointer
#include <boost/shared_ptr.hpp>

//....TODO What is this?
#include "boost/lexical_cast.hpp"

// LOCAL includes  (bare minimum!!)
#include "ISEExport.h"
#include "ConnectionHandler.h"
#include "Options.h"

namespace Samson_Peer {

// ===========================================================================
class ISE_Export CommandParser
{
public:

	//enum CmdType {TEXT, HTML, XML, XSL, JS};

	enum State {  Active = 0, Destroyed };

	CommandParser () : mySpiritParseRulePtr(new rule_type) {}
	~CommandParser ();

	int initialize(void);

	// This one is only called from the command line!!!!
	int process (const char *, ACE_HANDLE);

	// from the network
	int process (ConnectionHandler *, ACE_Message_Block *event);

	void set_connection_handler(ConnectionHandler *ch) { this->my_ch_ = ch; }
	ConnectionHandler *get_connection_handler() { return this->my_ch_; }

	static void cmd_status(ACE_HANDLE h, ACE_Message_Block *report_mb);

	ACE_Message_Block* create_ACE_Message_Block_Unified(const std::string& msg, const std::string& ctype = "TEXT", int rtncode = 200);
	ACE_Message_Block* create_OK (const std::string& ctype = "TEXT");
	ACE_Message_Block* create_NOT_OK (const std::string& ctype = "TEXT");

	ACE_Message_Block* create_ACE_Message_Block(const std::string& msg);
	ACE_Message_Block* create_ACE_Message_Block_as_HTTP(const std::string& msg, int rtncode = 200);
	//ACE_Message_Block* create_404(void);
	//ACE_Message_Block* create_204(void);
	// used to create the correct message block for output!

protected:

	boost::shared_ptr<rule_type> mySpiritParseRulePtr;
	// used to parse XML file

	ConnectionHandler *my_ch_;  // deprecated
	// used to send the output to the proper location

	State state_;
	// Used to ensure destroy is called
};


#if defined (__ACE_INLINE__)
#include "CommandParser.inl"
#endif /* __ACE_INLINE__ */


// =======================================================================
// Create a Singleton for the Application
// Manage this from DispatcherFactory::fini
typedef ACE_Unmanaged_Singleton<CommandParser, ACE_Recursive_Thread_Mutex> COMMAND_PARSER;

} // namespace

#endif
