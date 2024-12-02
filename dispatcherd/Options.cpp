/**
 *      @file Options.cpp
 *
 *      @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *      This is derived from the ACE Gateway Example Application
 *
 */

#define ISE_BUILD_DLL

// std includes
#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>

//....boost smart pointer
#include <boost/shared_ptr.hpp>

#include "ace/Get_Opt.h"
#include "ace/Log_Msg.h"
#include "ace/Message_Block.h"

#include "Options.h"

namespace Samson_Peer {


#if !defined (__ACE_INLINE__)
#include "Options.inl"
#endif /* __ACE_INLINE__ */

// Static initialization.
Options *Options::instance_ = 0;

// -----------------------------------------------------------------
Options *
Options::instance (void)
{
	if (Options::instance_ == 0)
		ACE_NEW_RETURN (Options::instance_, Options, 0);

	return Options::instance_;
}



// -----------------------------------------------------------------
void
Options::print_usage (void)
{
	ACE_DEBUG ((LM_DEBUG,
		"dispatcherd [-a acceptor-port] [-f xml-initialziation-file]"
		" [-t num] [-w time_out]"
		" [-b] [-v] [-T] [-Q size] [-B size] [-n] [-D]\n"
		""
		"\t-a Command port to listen on\n"
		"\t-f Use an initialization file to boot up\n"
		"\t-f Use an initialization file to boot up\n"
		"\t-b Use blocking connection establishment as default\n"
		"\t-t Use a different threading strategy\n"
		"\t-v Verbose mode\n"
		"\t-w Time performance for a designated amount of time\n"
		"\t-B Max buffer size with no header\n"
		"\t-Q Max queue size\n"
		"\t-N NETWORK Logging\n"
		"\t-O FILE Logging\n"
		"\t-D Run as daemon!!\n"
	));
}

// -----------------------------------------------------------------
Options::Options (void)
	: locking_strategy_ (0),
		performance_window_ (0),
		blocking_semantics_ (ACE_NONBLOCK),
		threading_strategy_ (REACTIVE),
		options_ (Options::DATABASE_INIT),
		command_port_ (DEFAULT_COMMAND_PORT),
		d2m_port_ (DEFAULT_D2M_PORT),
		d2d_port_ (DEFAULT_D2D_PORT),
		num_threads_(1),
		master_svc_(false),
		no_cache_(false),
		max_timeout_ (MAX_TIMEOUT),
		max_queue_size_ (MAX_QUEUE_SIZE),
		max_buffer_size_ (MAX_BUFFER_SIZE)
{
	this->initialization_file_.set("");
	this->pid_file_.set("./ise_pid");
	this->initialization_key_.set("dispatcher_default");
}

// -----------------------------------------------------------------
Options::~Options (void)
{
	delete this->locking_strategy_;
}

// -----------------------------------------------------------------
// Parse the "command-line" arguments and set the corresponding flags.
int
Options::parse_args (int argc, char *argv[])
{
	// Assign defaults.
	ACE_Get_Opt get_opt (argc,
		argv,
		"a:bcf:k:loiNSt:vw:B:Q:DO");

	for (int c; (argc != 0) && ((c = get_opt ()) != -1); )
	{
		switch (c)
		{
			case 'a':
				// TODO create a default read from environmental variable
				this->command_port_ = ACE_OS::atoi (get_opt.optarg);
			break;

			case 'B':
				// Internal compile-time default: MAX_BUFFER_SIZE
				this->max_buffer_size_ = ACE_OS::atoi (get_opt.optarg);
			break;

			case 'Q':
				// Internal compile-time default: MAX_QUEUE_SIZE
				this->max_queue_size_ = ACE_OS::atoi (get_opt.optarg);
			break;

			case 'b':
				// Internal compile-time default:  non-blocking
				// Use blocking connection establishment.
				this->blocking_semantics_ = 1;
			break;

			case 'c':
				this->no_cache_ = true;
			break;

			case 'f':
				// Use a configuration filename (relative or absolute).
				ACE_SET_BITS (this->options_, Options::FILE_INIT);
				this->initialization_file_.set(get_opt.optarg);
			break;

			case 'k':
				// Use a configuration key
				ACE_SET_BITS (this->options_, Options::DATABASE_INIT);
				this->initialization_key_.set(get_opt.optarg);
			break;

			case 't': // Use a different threading strategy.
			{
				this->num_threads_ = ACE_OS::atoi (get_opt.optarg);
			}
			break;

			case 'v':
				// Verbose mode.
				ACE_SET_BITS (this->options_, Options::VERBOSE);
			break;

			case 'w':
				// Time performance for a designated amount of time.
				this->performance_window_ = ACE_OS::atoi (get_opt.optarg);
				// Use blocking connection semantics so that we get accurate
				// timings (since all connections start at once).
				this->blocking_semantics_ = 0;
			break;

			case 'N':
				// Logging to logging services
				ACE_SET_BITS (this->options_, Options::NETLOG);
			break;

			case 'O':
				// Logging to logging services
				ACE_SET_BITS (this->options_, Options::OSTREAM);
			break;

			case 'S':
				// Logging to logging services
				ACE_SET_BITS (this->options_, Options::CMDSTDIN);
			break;

			case 'D':
				// Will be Daemonized
				ACE_SET_BITS (this->options_, Options::DAEMON);
				ACE_SET_BITS (this->options_, Options::NETLOG);
				ACE_CLR_BITS (this->options_, Options::OSTREAM);
				ACE_CLR_BITS (this->options_, Options::CMDSTDIN);
			break;

/*
			default:
				this->print_usage(); // It's nice to have a usage prompt.
			break;
*/
		}
	}

	// do some post processing sanity checks
	//
/*
	if ( this-> enabled (Options::DAEMON) )
	{
		ACE_SET_BITS (this->options_, Options::NETLOG);
		ACE_CLR_BITS (this->options_, Options::OSTREAM);
		ACE_CLR_BITS (this->options_, Options::CMDSTDIN);
	}
*/
	return 0;
}

//..................................................................................................
void
Options::print (void) const
{
	ACE_DEBUG ((LM_INFO, "(%P|%t) Options -> options_=%d\n",
			this->options_));
}

const std::string
Options::report (void)
{
	std::stringstream my_report;

	my_report
		<<  "Options" << std::endl
		<<  "------------------" << std::endl
		<< "DAEMON "   << ((ACE_BIT_ENABLED (this->options_, DAEMON))?"true":"false") << std::endl
		<< "DEBUG "    << ((ACE_BIT_ENABLED (this->options_, DEBUG))?"true":"false")  << std::endl
		<< "VERBOSE "  << ((ACE_BIT_ENABLED (this->options_, VERBOSE))?"true":"false")  << std::endl
		<< "CMDSTDIN " << ((ACE_BIT_ENABLED (this->options_, CMDSTDIN))?"true":"false") << std::endl
		<< "NETLOG "   << ((ACE_BIT_ENABLED (this->options_, NETLOG))?"true":"false")  << std::endl
		<<  "------------------" << std::endl;

	return my_report.str();
}

// =====================================================================
const std::string
Options::report_xml (void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/options.xsl");
		oa & boost::serialization::make_nvp("dispatcher",*this);
	}
	return my_report.str();
}

} // namespace
