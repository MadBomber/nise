#include "ISERelease.h"
#include "ISETrace.h" // first to toggle tracing

#include "ace/Service_Config.h"
#include "ace/Logging_Strategy.h"
#include "ace/Sig_Adapter.h"
#include "ace/Reactor.h"

int ACE_TMAIN(int argc, ACE_TCHAR *argv[])
{
	// ACE is compile with the tracing macros enabled, this may change as we stabalize
	// Turn off Trace Prints
	ACE_Trace::stop_tracing();

	// Trace on (use only in case of emergency!)
	// ACE_Trace::start_tracing();

	// Debug on (use only in case of emergency!)
	// ACE::debug(true);
	
	// Try to link in the svc.conf entries dynamically, enabling the
	// "ignore_debug_flag" as the last parameter so that we can override
	// the default ACE_Log_Priority settings in the svc.conf file.
	//
	// Warning - do not try to move the ACE_Reactor signal handling work
	// up to before this call - if the user specified -b (be a daemon),
	// all handles will be closed, including the Reactor's pipe.


	if (ACE_Service_Config::open(argc, argv, ACE_DEFAULT_LOGGER_KEY, 1, 0, 1)
			== -1)
	{
		if (errno != ENOENT)
			ACE_ERROR_RETURN((LM_ERROR, "(%P|%t) %p\n", "open"), 1);
		else // Use static linking.
		{
			ACE_ERROR_RETURN( (LM_ERROR,
					"(%P|%t) Static Linking not supported at this time.\n"), 1);
		}
	}
	else // Use dynamic linking.
	{
		ACE_Sig_Adapter sa((ACE_Sig_Handler_Ex) ACE_Reactor::end_event_loop);
		ACE_Sig_Set sig_set;
		sig_set.sig_add(SIGINT);
		sig_set.sig_add(SIGQUIT);
		// sig_set.sig_add (SIGKILL);
		sig_set.sig_add(SIGTERM);
		if (ACE_Reactor::instance ()->register_handler(sig_set, &sa) == -1)
			ACE_ERROR((LM_ERROR, "(%P|%t) %p\n", "register signals"));
		else
		{
			ACE_Reactor::instance ()->run_reactor_event_loop();
		}

	}
	return 0;
}
