/* -*- C++ -*- */

/**
 *	@file Options.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *	@brief Distributes command line options and default
 *
 */

#define ISE_BUILD_DLL

#include "ace/Get_Opt.h"
#include "ace/Log_Msg.h"
#include "ace/OS_NS_stdlib.h"
#include "ace/OS_NS_strings.h"
#include "ace/OS_NS_string.h"
#include "ace/OS_Memory.h"

#include "Options.h"

#define DEFAULT_PORT 8000

namespace Samson_Peer {

// Static initialization.
Options *Options::instance_ = 0;

// -----------------------------------------------------------------
/**
 * Print usages and die if there is an command line error
 *
 * @param none
 * @return none
 */
void
Options::print_usage_and_die (void)
{
  ACE_DEBUG ((LM_DEBUG,
              ACE_TEXT ("%n [-a acceptor-port] [-c connector-port][-h host] [-q max-queue-size] [-t timeout] [-o] [-N] [-d] [-v]\n")));
  ACE_OS::exit (1);
}


// -----------------------------------------------------------------
/**
 * Default Constructor
 *
 * @param  none
 * @return none
 */
Options::Options (void)
  : max_queue_size_ (MAX_QUEUE_SIZE),
	options_ (0),
	port_ (DEFAULT_PORT),
	host_ ("127.0.0.1"),
	header_ ("samson"),
	stall_timeout_(Options::DEFAULT_STALL_TIMEOUT),
	run_id_(0),
	unit_id_(0),
	num_threads_(1),
	app_key_ ("UNK")
{
}

// -----------------------------------------------------------------
/**
 * Return Singleton.
 *
 * @param  None
 * @return The address of the Option object
 */
Options *
Options::instance (void)
{
  if (Options::instance_ == 0)
    ACE_NEW_RETURN (Options::instance_, Options, 0);

  return Options::instance_;
}


// -----------------------------------------------------------------
/**
 * Parse the arguments and set the options.
 *
 * @param argc integer count of all the arguments
 * @param argv[] argument list
 */
void
Options::parse_args (int argc, ACE_TCHAR *argv[])
{
#if 0
	for (int i=0; i<argc; i++)
		ACE_DEBUG ((LM_DEBUG, "argv[%d] = %s\n",i, argv[i]));
#endif

	ACE_Get_Opt get_opt (argc, argv, OPT_PARSE_STRING, 0);

	for (int c; (argc != 0) && ((c = get_opt ()) != -1); )
	{
		//ACE_DEBUG ((LM_DEBUG, "Option %c\n",c));
		switch (c)
		{
			case 'a':
				// Make Active Connection on this port.
				ACE_SET_BITS (this->options_, Options::ACCEPTOR);
				this->port_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;

			case 'c':
				// Listen for a connection on this port.
				ACE_SET_BITS (this->options_, Options::CONNECTOR);
				this->port_ = ACE_OS::atoi (get_opt.opt_arg ());
			break;

			case 'e':
				// Compiled inside of another.
				ACE_SET_BITS (this->options_, Options::EMBEDDED);
				ACE_SET_BITS (this->options_, Options::OSTREAM);
			break;

			case 'j':
				// Sets the Job ID for this Model (not for service)
				this->run_id_ = ACE_OS::atoi (get_opt.opt_arg ());
				break;

			case 'k':
				//  A human readable key
				this->app_key_ = get_opt.opt_arg ();
				break;

			case 'l':
				//  The shared library to load
				this->app_lib_ = get_opt.opt_arg ();
				break;

			case 'S':
				// Turn on stdin
				ACE_SET_BITS (this->options_, Options::STDIN);
				break;

			case 'N':
				// Turn on Network Logging
				ACE_SET_BITS (this->options_, Options::NETLOG);
				break;

			case 'O':
				// Log to stdout
				ACE_SET_BITS (this->options_, Options::OSTREAM);
				break;

			case 'h':
				// connect to this host (used with a -a)
				this->host_ = get_opt.opt_arg ();
			break;

			case 'H':
				// header type for command channel (depreciated)
				this->header_ = get_opt.opt_arg ();
			break;

			case 'T':
				// Timeout for Stall
				this->stall_timeout_ = ACE_OS::atof (get_opt.opt_arg ());
				break;

			case 't': // Use a different threading strategy.
			{
				this->num_threads_ = ACE_OS::atoi (get_opt.optarg);
			}
			break;


			case 'u':
				// Set UnitID or InstanceID
				this->unit_id_ = ACE_OS::atoi (get_opt.opt_arg ());
				break;
		}
	}
}

}
