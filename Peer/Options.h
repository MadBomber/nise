/* -*- C++ -*- */

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
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef OPTIONS_H
#define OPTIONS_H

#include "ace/Lock_Adapter_T.h"
#include "ace/Synch_Traits.h"
#include "ace/Thread_Mutex.h"

#include "ISE.h"
#define OPT_PARSE_STRING ACE_TEXT("a:c:d:eh:j:k:l:ih:H:m:n:NOq:St:T:u:v")

namespace Samson_Peer
{

class ISE_Export Options
// = TITLE
//     Singleton that consolidates all Options for a peerd.

{
public:
	// = Options that can be enabled/disabled.
	enum
	{
		STDIN = 0x0001,
		ACCEPTOR = 0x0002,
		CONNECTOR = 0x0004,
		OSTREAM = 0x0008,
		CONTROLLER = 0x0010,
		EMBEDDED = 0x0020,
		NETLOG = 0x0040
	};

	// Destructor
	~Options (void)
	{}

	static Options *instance (void);
	// Return Singleton.

	void parse_args (int argc, ACE_TCHAR *argv[]);
	// Parse the arguments and set the options.

	// = Accessor methods.
	int enabled (int option) const
	{	return ACE_BIT_ENABLED (this->options_, option);}
	// Determine if an option is enabled.

	void enable (int option)
	{	ACE_SET_BITS (this->options_, option);}
	// Enable an option

	void disable (int option)
	{	ACE_CLR_BITS (this->options_, option);}
	// Disable an option

	unsigned short port (void) const
	{	return port_;}
	// Port to connect to  (We can be active or passive, currently we only work active)

	unsigned int jobID (void)
	{	return run_id_;}
	// Returns the application ID passed on the command line

	const ACE_TCHAR *appKey (void) const
	{	return app_key_;};
	// Our application key.

	const ACE_TCHAR *appLib (void) const
	{	return app_lib_;};
	// Our Physics model DLL.

	const ACE_TCHAR *host (void) const
	{	return host_;};
	// The host to connect to. (should default to 127.0.0.1)

	const ACE_TCHAR *header (void) const
	{	return header_;};
	// The type of header.  (not used???)

	double stall_timeout (void) const
	{	return stall_timeout_;}
	// Stall check duration.

	int unitID(void)
	{	return this->unit_id_;}
	//  aka instance ID

	int
	max_queue_size (void) const
	{
		return this->max_queue_size_;
	}

	int
	num_threads (void) const
	{
	    return this->num_threads_;
	}

	//long option_flag() { return options_; }

private:
	enum
	{
		MAX_QUEUE_SIZE = 1024 * 1024 * 16
		// We'll allow up to 16 megabytes to be queued per-output proxy.
	};

	const static double DEFAULT_STALL_TIMEOUT = 10.0;
	// By default, an app will stall if there is no activity in 10 seconds.

	Options (void);
	// Ensures Singleton.

	void print_usage_and_die (void);
	// Explain usage and exit.

	static Options *instance_;
	// Singleton.

	int max_queue_size_;
	// TODO Not sure how this is used?

	unsigned long options_;
	// Flag to indicate if we want verbose diagnostics.

	unsigned short port_;
	// The acceptor port number, i.e., the one that we passively listen
	// on for connections to arrive from a gatewayd
	//  ... or ...
	// The connector port number, i.e., the one that we use to actively
	// establish connections with a gatewayd

	const ACE_TCHAR *app_lib_;
	// Our Samson Applicaiton shared object to load

	const ACE_TCHAR *host_;
	// Our connector host, i.e., where the gatewayd process is running.

	const ACE_TCHAR *header_;
	// Our connector host, i.e., where the gatewayd process is running.

	double stall_timeout_;
	// The amount of time to wait before detecting a stall.

	unsigned int run_id_;
	// The Samson job id.

	unsigned int unit_id_;
	// The Samson UnitId

	int num_threads_;
	// number of threads to use

	const ACE_TCHAR *app_key_;
	// Our application key
};

} // namespace

#endif /* OPTIONS_H */
