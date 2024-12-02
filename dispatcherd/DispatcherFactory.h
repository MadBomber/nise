/**
 * @file DispatcherFactory.h
 *
 * @class DispatcherFactory
 *
 * @brief Factory to create the Simulation Dispatcher Service Object
 *
 * Based on original work of Douglas Schmidt
 * Adapted by Jack Lavender of Systems Engineering Associates under contract to
 * Lockheed Martin Missiles and Fire Control in 2001
 *
 * @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef _DISPATCHER_FACTORY_H
#define _DISPATCHER_FACTORY_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include "ace/svc_export.h"  // required for ACE_SVC_FACTORY_DECLARE
#include "ace/Svc_Handler.h"

namespace Samson_Peer {




// ===============================================================================
// The following is a "Factory" used by the ACE_Service_Config and
// svc.conf file to dynamically initialize the state of the Router.

ACE_SVC_FACTORY_DECLARE (DispatcherFactory);

// ===============================================================================
// forward declarations
class CommandHandler;

// ===============================================================================
class ISE_Export DispatcherFactory : public ACE_Service_Object
{
protected:

	// = Service configurator hooks.
	virtual int init (int argc, char *argv[]);
	// Perform initialization.

	virtual int fini (void);
	// Perform termination when unlinked dynamically.

	virtual int info (char **, size_t) const;
	// Return info about this service.

	virtual int handle_timeout (const ACE_Time_Value &tv, const void *arg);
	// Handle timeouts for this service

	// = Stdin management methods.
	int handle_input (ACE_HANDLE);
	// Shut down the application when input comes in from the controlling
	// console.

	int LoggerControl (int argc, char *argv[]);
	// Control Logging

	//int handle_signal (int, siginfo_t * = 0, ucontext_t * = 0);
	// Shut down the application when a signal arrives.

	bool cmd_stdin_;
	// if the stdin handler was registered

	ofstream *log_ostream_;
	// The ouput file stream for Logging

	long persist_timer_;
	// Database Persisance Timer

};


} // namespace

#endif  // _DISPATCHER_FACTORY_H

