/**
 *	@file DispatcherFactory.cpp
 *
 *  @brief Factory to startup/closedown ISE dispatcher
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ACE_BUILD_SVC_DLL

#include "DispatcherFactory.h"
#include "Options.h"
#include "DebugFlag.h"
#include "EventChannel.h"
#include "Service_ObjMgr.h"
#include "XMLParser.h"
#include "CommandParser.h"
#include "ISETask.h"
#include "SubscriptionCache.h"

#include "ace/streams.h"
#include "ace/Service_Config.h"
#include "ace/Signal.h"
#include "ace/Sig_Adapter.h"


namespace Samson_Peer
{

// ===========================================================================
ACE_SVC_FACTORY_DEFINE(DispatcherFactory);

// ===========================================================================
/*
 int
 DispatcherFactory::handle_signal (int, siginfo_t *, ucontext_t *)
 {
 // Shut down the main event loop.  (returns 0 per ace/Reactor.i)
 return ACE_Reactor::end_event_loop ();
 }
 */


int DispatcherFactory::handle_timeout (const ACE_Time_Value &tv, const void *arg)
{
	ACE_TRACE("DispatcherFactory::handle_timeout");

	int timer_tag = static_cast <int> (reinterpret_cast <size_t> (arg));
	ACE_UNUSED_ARG(tv);

	ACE_DEBUG((LM_DEBUG,"(%P|%t) DispatcherFactory::handle_timeout(%d)\n",timer_tag));

	if ( timer_tag ==  1001 )
	{
		if ( SAMSON_OBJMGR::instance()->persist_check() == -1 )
		{
			ACE_DEBUG((LM_ERROR,"(%P|%t) DispatcherFactory::handle_timeout() -> Database Error during persitance check.\n"));
		}
	}
	return 0;
}



// ===========================================================================
// TODO:  This needs to be moved to a separate area on the next version
int DispatcherFactory::handle_input(ACE_HANDLE h)
{
	char buf[BUFSIZ];

	// Consume the input...
	ssize_t n = ACE_OS::read(h, buf, sizeof buf - 1);

	if (n > 0)
	{
		COMMAND_PARSER::instance ()->process(buf, h);
	}

	return 0;
}

// ===========================================================================
int DispatcherFactory::init (int argc, char *argv[])
{
	ACE_TRACE("DispatcherFactory::init");

	// Not using contructor due to ACE Service interface, set object up here

	persist_timer_ = -1;  // no main database persistence timer setup
	this->cmd_stdin_ = false;  // don't accept commands from stdin

	// Parse the "command-line" arguments.
	Options::instance ()->parse_args(argc, argv);

#if 0
	// Write out the PID
	// Assumption:  init script will remove this

	{
		ofstream pid_ofs(Options::instance ()->pid_file()->c_str ());
		pid_ofs << ACE_OS::getpid();
		pid_ofs.close();
	}
#endif

	// Parse the command line for Debug Control
	DebugFlag::instance ()->parse_args(argc, argv);

	/**
	 *  Order is specific!  DO NOT CHANGE, unless you are sure.
	 *  For example EventChanel requires MySQL to be up an running.
	 */

	/**
	 *  Initialize the Logging Singleton;
	 */
	if (this->LoggerControl (argc, argv) < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) Logger Control failed to initialize\n"), -1);
	}

	/**
	 *  Initialize the XML Parser;
	 */
	else if (XML_PARSER::instance()->initialize () < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) XML Parsing Singleton failed to initialize\n"), -1);
	}

	/**
	 *  Initialize the Command Handler;
	 *    This is not an ACE_Svc_Hander, processes commands
	 */
	else if (COMMAND_PARSER::instance ()->initialize() < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) Command Singleton failed to initialize\n"), -1);
	}

	/**
	 *  Initialize the MySQL Database;
	 */
	else if (SAMSON_OBJMGR::instance()->initialize("dispatcher") < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) Object Management Singleton failed to initialize\n"),
				-1);
	}



	/**
	 *  Initialize EVENT_CHANNEL_MGR
	 */
	else if (EVENT_CHANNEL_MGR::instance()->initialize() < 0)
	{
		ACE_ERROR_RETURN(
				(LM_ERROR,
						"(%P|%t) Event Channel Management Singleton failed to initialize\n"),
				-1);
	}

	/**
	 *  Initialize ISETask Threads;
	 */
	else if (ISETask::instance()->start(Options::instance ()->num_threads ()) < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) ISETask Singleton failed to initialize\n"),
				-1);
	}

	/**
	 *  The configuration came in via a file  (processes ALL tags)
	 */
	else if (Options::instance ()->enabled(Options::FILE_INIT))

	{
		if (Options::instance ()->initialization_file ()->length() > 0)
		{
			int result = XML_PARSER::instance ()->fprocess(Options::instance ()->initialization_file ()->c_str());
			if (result < 0)
				ACE_ERROR_RETURN(
						(LM_ERROR,
								"(%P|%t) XML_PROCESSOR failed to process initialization file\n"),
						-1);
		} else {
			ACE_ERROR_RETURN(
				(LM_ERROR,
				"(%P|%t) XML_PROCESSOR failed to process initialization file, filename empty\n"),
				-1);
		}
	}

	/**
	 *  Or we are to read the default configuration from the database
	 */
	else if (Options::instance ()->enabled(Options::DATABASE_INIT))
	{
		ACE_CString temp;
		int result = SAMSON_OBJMGR::instance ()->KeyValueQuery(Options::instance ()->initialization_key ()->c_str(), temp);
		if (result < 0)
			ACE_ERROR_RETURN(
					(LM_ERROR,
							"(%P|%t) SAMSON_OBJMGR could not find dispatcher_default\n"),
					-1);

		//ACE_DEBUG((LM_DEBUG,"From Database (%s)\n",temp.c_str()));

		result = XML_PARSER::instance ()->process(temp.c_str());
		if (result < 0)
			ACE_ERROR_RETURN(
					(LM_ERROR,
							"(%P|%t) XML_PROCESSOR failed to process initialization string\n"),
					-1);
	}


	/*
	 *  Object initialization complete, now prepare processing
	 */

	if (Options::instance ()->enabled(Options::CMDSTDIN))
	{
		this->cmd_stdin_ = true;

		if (ACE_Event_Handler::register_stdin_handler( this,
				ACE_Reactor::instance(), ACE_Thread_Manager::instance()) == -1)
			ACE_ERROR_RETURN((LM_ERROR, "(%P|%t) %p\n",
					"register_stdin_handler"), -1);

		//ACE_DEBUG((LM_DEBUG,"Standard Input was enabled.\n"));

	}

	// Now open all the the channels for processing
	int ec_result = EVENT_CHANNEL_MGR::instance ()->open();

	if (Options::instance ()->enabled(Options::NETLOG))
	//if (Options::instance ()->enabled (Options::VERBOSE))
	{
		EVENT_CHANNEL_MGR::instance ()->print();

		if (Options::instance ()->enabled(Options::CMDSTDIN))
			ACE_DEBUG((LM_DEBUG,
					"(%P|%t) DispatcherFactory::init() -> Standard Input was enabled.\n"));
	}

	// now for timer
	{
		int timer_persist_flag = 1001;
		ACE_Time_Value const recur_time (600.0);
		if ( (this->persist_timer_ = ACE_Reactor::instance ()->schedule_timer (this, (const void *) timer_persist_flag, recur_time, recur_time)) == -1)
			ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "schedule_timer"));
		ACE_DEBUG ((LM_INFO, "(%P|%t) DispatcherFactory::init()-> scheduling DB timer(%d) every %f seconds\n",
				this->persist_timer_, (recur_time.msec()/1000.0)));
	}

	SAMSON_OBJMGR::instance ()->status(2); // we are initialized!


	return ec_result;
}

// ===========================================================================
// This method is automatically called when the Router is shutdown.

int DispatcherFactory::fini(void)
{
	ACE_TRACE("DispatcherFactory::fini");

	//Cancel timer(s)
	if ( this->persist_timer_ != -1 )
	{
		ACE_Reactor::instance ()->cancel_timer (this->persist_timer_);
		this->persist_timer_ = -1;
	}


	//ACE_Trace::start_tracing();

	// Close down the command parser
	COMMAND_PARSER::close();

	// Close down the event channel.
	EVENT_CHANNEL_MGR::close();

	// Close down the object manager
	SAMSON_OBJMGR::close();

	// Clean up Misc Tables;
	SUBSCR_SET::instance ()->destroy();
	SUBSCR_SET::close();

	// Close down the XML parser
	XML_PARSER::close();

	// If we opened up stdin to process commands
	if (this->cmd_stdin_)
	{
		// Remove the handler that receive events on stdin.  Otherwise, we
		// will crash on shutdown.
		ACE_Event_Handler::remove_stdin_handler(ACE_Reactor::instance(),
				ACE_Thread_Manager::instance());
		// Reset standard input.
		ACE_OS::rewind(stdin);
	}

	if (Options::instance ()->enabled(Options::OSTREAM))
	{
		ACE_LOG_MSG->clr_flags(ACE_Log_Msg::OSTREAM);
		ACE_LOG_MSG->set_flags(ACE_Log_Msg::STDERR);
	}
	else if (Options::instance ()->enabled(Options::NETLOG))
	{
		ACE_LOG_MSG->clr_flags(ACE_Log_Msg::LOGGER);
		ACE_LOG_MSG->set_flags(ACE_Log_Msg::STDERR);
	}

	return 0;
}

// ===========================================================================
// Returns information on the currently active service.

int DispatcherFactory::info(char **strp, size_t length) const
{
	char buf[BUFSIZ];

	ACE_OS::sprintf(buf, "%s\t %s", "Router daemon",
			"# Application-level gateway\n");

	if (*strp == 0 && (*strp = ACE_OS::strdup(buf)) == 0)
		return -1;
	else
		ACE_OS::strncpy(*strp, buf, length);
	return ACE_OS::strlen(buf);
}

// ===========================================================================
// Redirects the ACE_DEBUG (Logging) output.
// Note: this needs to be called prior to spawning threads.

int DispatcherFactory::LoggerControl (int argc, char *argv[])
{
	ACE_UNUSED_ARG (argc);

	/**
	 * Redirect the output if desired.
	 */
	if (Options::instance ()->enabled(Options::OSTREAM))
	{
		// Create a persistent store.
		char filename[80];
		ACE_OS::sprintf(filename, "dispatcher_%d.log", ACE_OS::getpid());
		log_ostream_ = SAMSON_OBJMGR::instance()->CreateOutputFile(filename);

		// Check for errors.
		if (log_ostream_->bad())
		{
			ACE_ERROR_RETURN((LM_ERROR,
					"(%P|%t) DispatcherFactory::init ->%p\n",
					ACE_TEXT("Ostream::open")), -1);
		}

		// Set the ostream.
		ACE_LOG_MSG->clr_flags(ACE_Log_Msg::STDERR);
		ACE_LOG_MSG->set_flags(ACE_Log_Msg::OSTREAM);
		ACE_LOG_MSG->msg_ostream(log_ostream_);
	}
	else if (Options::instance ()->enabled(Options::NETLOG))
	{
		ACE_LOG_MSG->set_flags(ACE_Log_Msg::LOGGER);
		ACE_LOG_MSG->open(argv[0], ACE_Log_Msg::LOGGER, ACE_DEFAULT_LOGGER_KEY);
	}

	return 1;
}

} // namespace

