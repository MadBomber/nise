/**
 *	@file Options.h
 *
 *	@class Options
 *
 *	@brief Distributes command line options and default
 *
 *	This Singleton object is used to dissiminate default and command
 *	line options thoughout the program
 *
 * 	Based upon work by Douglas Schmidt
 *
 *	@note Attempts at zen rarely work.
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>, (C) 2006
 *

 */

#ifndef DISPATCHER_OPTIONS_H
#define DISPATCHER_OPTIONS_H

#include "ISE.h"
#include "DispatcherConfig.h"

#include "ace/config-all.h"
#include "ace/Service_Config.h"
#include "ace/Lock_Adapter_T.h"
#include "ace/Synch_Traits.h"
#include "ace/Thread_Mutex.h"
#include "ace/SString.h"

//....boost serialization
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"


namespace Samson_Peer {


// Default port to establish as dispatcher's command.
#define DEFAULT_COMMAND_PORT 8010

// Default port to communicate with models
#define DEFAULT_D2M_PORT 8001

// Default port to comunicate between dispatchers
#define DEFAULT_D2D_PORT 8002

class ISE_Export Options
{
	// = TITLE
	//     Singleton that consolidates all Options for a gatewayd.
public:
	// = Options that can be enabled/disabled.
	enum
	{
		// = The types of threading strategies.
		REACTIVE   = 0x0000,
		OUTPUT_MT  = 0x0001,
		INPUT_MT   = 0x0002,
		VERBOSE    = 0x0004,
		DEBUG      = 0x0008,
		OSTREAM    = 0x0010,
		NETLOG     = 0x0020,
		DAEMON     = 0x0040,
		CMDSTDIN   = 0x0080,

		FILE_INIT  = 0x0100,
		DATABASE_INIT = 0x0200
	};

	~Options (void);
	// Termination.

	static Options *instance (void);
	// Return Singleton.

	int parse_args (int argc, char *argv[]);
	// Parse the arguments and set the options.

	void print_usage(void);
	// Print the gateway supported parameters.


	// ---- Internal Debug Stuff ----
	void print (void) const;
	const std::string report (void);
	const std::string report_xml (void);

	template<class Archive>
	void serialize(Archive & ar, const unsigned int /* file_version */)
	{
	  using boost::serialization::make_nvp;
		ar
		& make_nvp("options"      , options_)
		& make_nvp("command_port" , command_port_)
		& make_nvp("d2d_port"     , d2d_port_)
		& make_nvp("d2m_port"     , d2m_port_)
		& make_nvp("num_threads"  , num_threads_)
		& make_nvp("no_cache"     , no_cache_)
		& make_nvp("num_threads"  , num_threads_)
		& make_nvp("max_timeout"  , max_timeout_)
		& make_nvp("max_queue_size" , max_queue_size_)
		& make_nvp("max_buffer_size"  , max_buffer_size_)
		;
	}

	// = Accessor methods.

	inline void enable (int option);
	inline void disable (int option);
	inline int enabled (int option) const;
	// Determine if an option is enabled.


	inline ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *locking_strategy (void) const;
	// Gets the locking strategy used for serializing access to the
	// reference count in <ACE_Message_Block>.  If it's 0, then there's
	// no locking strategy and we're using a REACTIVE concurrency
	// strategy.

	inline void locking_strategy (ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *);
	// Set the locking strategy used for serializing access to the
	// reference count in <ACE_Message_Block>.

	inline int performance_window (void) const;
	// Number of seconds after connection establishment to report
	// throughput.

	inline int blocking_semantics (void) const;
	// 0 == blocking connects, ACE_NONBLOCK == non-blocking connects.

	inline int num_threads (void) const;
	// 0 == blocking connects, ACE_NONBLOCK == non-blocking connects.

	inline u_long threading_strategy (void) const;
	// i.e., REACTIVE, OUTPUT_MT, and/or INPUT_MT.

	inline u_short command_port (void) const;
	// access the command port number

	inline u_short d2m_port (void) const;
	// access the command port number

	inline u_short d2d_port (void) const;
	// access the command port number

	inline const ACE_CString *initialization_file (void) const;
	// Name of the configuration file.

	inline const ACE_CString *initialization_key (void) const;
	// Name of the configuration key value.

	inline const ACE_CString *pid_file (void) const;
	// Name of the PID file when daemonized.

	inline long max_timeout (void) const;
	// The maximum retry timeout delay.

	inline long max_queue_size (void) const;
	// The maximum size of the queue.

	inline long max_buffer_size (void) const;
	// The maximum size of a no-header buffer.

	inline bool isMaster(void);

	inline bool no_cache() const;

private:

	Options (void);
	// Initialization.

	static Options *instance_;
	// Singleton.


	enum
	{
		MAX_QUEUE_SIZE = 1024 * 1024 * 16,
		// We'll allow up to 16 megabytes to be queued per-output proxy.

		MAX_BUFFER_SIZE = 1024,
		// The default maximum buffer size for a "no-header" connection

		MAX_TIMEOUT = 32
		// The maximum timeout for trying to re-establish connections.
	};


	ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *locking_strategy_;
	// Points to the locking strategy used for serializing access to the
	// reference count in <ACE_Message_Block>.  If it's 0, then there's
	// no locking strategy and we're using a REACTIVE concurrency
	// strategy.

	int performance_window_;
	// Number of seconds after connection establishment to report
	// throughput.

	int blocking_semantics_;
	// 0 == blocking connects, ACE_NONBLOCK == non-blocking connects.

	int socket_queue_size_;
	// Size of the socket queue (0 means "use default").

	u_long threading_strategy_;
	// i.e., REACTIVE, OUTPUT_MT, and/or INPUT_MT.

	u_long options_;
	// Flag to indicate if we want verbose diagnostics.

	u_short command_port_;
	// The command acceptor port number, i.e., the one that we passively listen
	// on for command connections to arrive from a Peer

	u_short d2m_port_;
	// The dispatcher to model acceptor port number

	u_short d2d_port_;
	// The dispatcher to dispatcher acceptor port number

	int num_threads_;
	// number of threads to use

	bool master_svc_;
	// Register this as the Master for this JobID

	bool no_cache_;
	//  Default is to cache the database routing queries

	long max_timeout_;
	// The maximum retry timeout delay.

	long max_queue_size_;
	// The maximum size of the queue.

	long max_buffer_size_;
	// The maximum size of a buffer with no header.

	ACE_CString initialization_file_;
	// Name of the connection configuration file.

	ACE_CString pid_file_;
	// Name of the pid file.

	ACE_CString initialization_key_;
	//  Key for initialization from name-value table in database

};

#if defined (__ACE_INLINE__)
#include "Options.inl"
#endif /* __ACE_INLINE__ */

} // namespace

#endif /* DISPATCHER_OPTIONS_H */
