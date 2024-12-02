/* -*- C++ -*- */

/**
 *	@file Peer_Factory.cpp
 *
 *	@brief Distributes command line options and default
 *
 *	Documentation
 *
 * 	Based upon work by Douglas Schmidt
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "ace/Reactor.h"
#include "ace/TP_Reactor.h"
#include "ace/Signal.h"

#include "Options.h"
#include "DebugFlag.h"
#include "Peer_Factory.h"
#include "Model_ObjMgr.h"
#include "SharedAppMgr.h"
#include "Peer_Handler.h"  // used to register stdin
#include "ISETask.h"

namespace Samson_Peer {


// ========================================================================================
// ========================================================================================
// ========================================================================================
// ========================================================================================
// ========================================================================================
// ========================================================================================
/**
 * Graceully terminate the application
 *
 * @param signum
 * @param
 * @param
 * @return
 */
int
Peer_Factory::handle_signal (int /* signum */, siginfo_t *, ucontext_t *)
{
  //if (signum == SIGINT || signum == SIGQUIT)
  //{
    // Shut down the main event loop.
    ACE_Reactor::instance ()->end_reactor_event_loop();
  //}

  return 0;
}

// ........................................................................................
/**
 * Returns information on the currently active service.  (NOT TESTED!!!)
 * @param strp
 * @param length
 * @return number of bytes in meessage
 */
int
Peer_Factory::info (ACE_TCHAR **strp, size_t length) const
{
  ACE_TCHAR buf[BUFSIZ];

  ACE_OS::strcpy (buf, ACE_TEXT ("peerd\t"));
   ACE_OS::strcat
    (buf, ACE_TEXT ("ISE Peer INFO\n"));

  if (*strp == 0 && (*strp = ACE_OS::strdup (buf)) == 0)
    return -1;
  else
    ACE_OS::strncpy (*strp, buf, length);
  return ACE_OS::strlen (buf);
}

// ........................................................................................
/**
 * Hook called by the explicit dynamic linking facility to terminate the peer.
 * @param  none
 * @return always returns 0
 */
int
Peer_Factory::fini (void)
{
	// Remove the handler that receive events on stdin.  Otherwise, we will crash on shutdown.
	if (this->stdin_handler_)
	{
		ACE_Event_Handler::remove_stdin_handler (ACE_Reactor::instance (), ACE_Thread_Manager::instance ());
		delete this->stdin_handler_;
	}

	// This passes it over to the AppBase Object
	SAMSON_APPMGR::instance ()->close ();

	// Close the database, this is required Singleton's persistance
	SAMSON_OBJMGR::instance ()->close();

	// This should not cause any grief even if we did not use it.
	this->acceptor_.close ();


	// If we were logging to a file, then close it down properly
	if ( this->log_ostream_ && Options::instance ()->enabled (Options::OSTREAM) )
	{
		ACE_LOG_MSG->set_flags (ACE_Log_Msg::STDERR);
		ACE_LOG_MSG->clr_flags (ACE_Log_Msg::OSTREAM);
		this->log_ostream_->close ();
		delete this->log_ostream_;
	}

	return 0;
}

// ........................................................................................
/**
 * Hook called by the explicit dynamic linking facility to initialize the peer.
 *
 * @param argc  Command line argument count
 * @param argv[] Comman line arguments
 *
 * @return 0 for success, -1 for failure
 */
int
Peer_Factory::init (int argc, ACE_TCHAR *argv[])
{
	// Parse the command line for Options
	Options::instance ()->parse_args (argc, argv);

	// Parse the command line for Debug Control
	DebugFlag::instance ()->parse_args (argc, argv);

	/**
	 * Initialze the Peer_Handler, this will be given to the Samson Applications
	 * Both the passive and active logic will allocate the handler.
	 */
	Peer_Handler *ph=0;

	/**
	 * Set the default value for the Stdin Handler
	 * Reading from stdin is an option, not currently used!
	 */
	this->stdin_handler_ = 0;

	/**
	 * Initialize the logging stream!
	 */
	this->log_ostream_ = 0;

#if 0
	/**
	 *  Initialize ISETask Threads;
	 */
	if (ISETask::instance()->start(Options::instance ()->num_threads ()) < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t) ISETask Singleton failed to initialize\n"),
				-1);
	}
#endif

	/**
	 * Register for signals so we can gracefully shutdown
	 * Note:  This is NOT done when we are embedded, which is on Windows for now.
	 */
	if ( !Options::instance ()->enabled (Options::EMBEDDED))
	{
		ACE_Sig_Set sig_set;
		sig_set.sig_add (SIGINT);
		sig_set.sig_add (SIGTERM);
		sig_set.sig_add (SIGQUIT);
		sig_set.sig_add (SIGPIPE);
		if (ACE_Reactor::instance ()->register_handler (sig_set, this) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init -> %p\n", "register_handler"), -1);
	}

	/**
	 * The order is very specific here
	 * 1. the object manager registers the application with the database
	 * 2. then we open the communications with the dispatcher, which will do the
	 *	"hello" exchange that requires information from step 1.
	 * 3. then we initialize the applicaitons to receive events.
	 *
	 * I have not experimented much with reordering this, but to do so will
	 * probably require rethinking where data is stored
	 *
	 * TODO The problem is we would like the application to tell us about it before we
	 * start, that may be possible but the peer_handler will not be setup yet. At this time
	 * we pass in the appKey on the command line
	*/

	/**
	 * Initialize the Samson Object Manager (and the MySQL Database);
	 */
	if ( SAMSON_OBJMGR::instance()->initialize(
				Options::instance ()->appKey(),
				Options::instance ()->appLib(),
				Options::instance ()->jobID(),
				Options::instance ()->unitID()) < 0 )
	{
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init -> Object Manager failed to initialize\n"), -1);
	}
	/**
	 * Redirect the output if desired.
	 * Note: do NOT register a hander for stdin if this occurs!!
	 */
	else if (Options::instance ()->enabled (Options::OSTREAM))
	{
		// Create a persistent store.
		char filename[80];
		ACE_OS::sprintf(filename,"%s%d.txt",
						Options::instance()->appKey(),
						Options::instance()->unitID());

		log_ostream_ = SAMSON_OBJMGR::instance()->CreateOutputFile(filename);

		// Check for errors.
		if (log_ostream_->bad ())
		{
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init ->%p\n", ACE_TEXT ("Ostream::open")), -1);
		}

		// Set the ostream.
		ACE_LOG_MSG->clr_flags (ACE_Log_Msg::STDERR);
		ACE_LOG_MSG->set_flags (ACE_Log_Msg::OSTREAM);
		ACE_LOG_MSG->msg_ostream (log_ostream_);
	}

	/**
	 * Redirect the output to the network loggging service
	 */
	else if (Options::instance ()->enabled (Options::NETLOG))
	{
		ACE_LOG_MSG->set_flags (ACE_Log_Msg::LOGGER);
		ACE_LOG_MSG->open(argv[0],ACE_Log_Msg::LOGGER,ACE_DEFAULT_LOGGER_KEY);
	}

	/**
	 * Start the Sockets (we will enter one of the following blocks)
	 * to setup an active or passive connection.  Most of my testing was active (connector).
	 */
	if (Options::instance ()->enabled (Options::ACCEPTOR))
	{
		if (this->acceptor_.start (Options::instance ()->port ()) == -1)
		{
			ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT ("(%P|%t) Peer_Factory::init -> %p\n"), ACE_TEXT ("Acceptor::open")), -1);
		}
		ph = this->acceptor_.peer_handler();
	}
	else
	{
		if (this->connector_.open () == -1)
		{
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init -> %p\n", ACE_TEXT ("Connector::open")), -1);
		}
		ph = this->connector_.peer_handler();
	}

	/**
	 * This call brings the Samson Application into existance and gives it the Peer Handler
	 */
	if ( SAMSON_APPMGR::instance ()->init(ph, embedded_app_, argc, argv) < 0 )
	{
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init -> Application failed to initialize\n"), -1);
	}

	/**
	 *  Print this out if we have an ostream opened
	 */
	if (DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
	{
		SAMSON_OBJMGR::instance ()->print ();
		SAMSON_APPMGR::instance ()->print_map_all ();

	}

	/**
	 * Register a standard input handler if requested
	 */

	if (Options::instance ()->enabled (Options::STDIN))
	{
		if (!this->stdin_handler_) this->stdin_handler_ = new Peer_Stdin_Handler ();

		if (ACE_Event_Handler::register_stdin_handler (
					this->stdin_handler_, ACE_Reactor::instance (), ACE_Thread_Manager::instance ()) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) Peer_Factory::init -> %p\n", "register_stdin_handler"), -1);
	}



	return 0;
}

/**
 * The following is a "Factory" used by the <ACE_Service_Config> and
 * svc.conf file to dynamically initialize the <Peer_Acceptor> and
 * <Peer_Connector>.
 */
//ACE_SVC_FACTORY_DEFINE (Peer_Factory)
ACE_FACTORY_DEFINE (ISE, Peer_Factory)

}
