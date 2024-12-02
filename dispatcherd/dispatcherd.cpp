// ============================================================================
// Based on original work of Douglas Schmidt
// Adapted by Jack Lavender of Systems Engineering Associates under contract to
//	Lockheed Martin Missiles and Fire Control in 2001

#include "ISE.h"

#include "ace/OS_NS_unistd.h"
#include "ace/Service_Config.h"
//#include "ace/Service_Object.h"
#include "ace/Sig_Adapter.h"
#include "ace/Log_Msg.h"
#include "ace/Reactor.h"

#include "DispatcherFactory.h"

using namespace Samson_Peer;

int
ACE_TMAIN (int argc, ACE_TCHAR *argv[])
{
	// Turn off Trace Prints
	ACE_Trace::stop_tracing();

	// This supports loading from a DLL

	if (ACE_OS::access (ACE_DEFAULT_SVC_CONF, F_OK) != 0)
	{
		ACE_ERROR_RETURN ((LM_ERROR,"%s\n", "Static Linking not supported at this time"), 1);
#if 0
		// Use static linking (NO DLL)
		ACE_Service_Object_Ptr sp = ACE_SVC_INVOKE (DispatcherFactory);

		if (sp->init (argc - 1, argv + 1) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) %p\n", "Dispatcher init"), 1);

		/**
		 * Setup signals for processing
		 */	
		ACE_Sig_Adapter sa ((ACE_Sig_Handler_Ex) ACE_Reactor::end_event_loop);
		ACE_Sig_Set sig_set;
		sig_set.sig_add (SIGINT);
		sig_set.sig_add (SIGQUIT);
		sig_set.sig_add (SIGTERM);

		/**
		 *  Register to receive signals so we can shut down gracefully.
		 */
		if (ACE_Reactor::instance ()->register_handler (sig_set, &sa) == -1)
			ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "register_handler"));
		else
		{
			//ACE_Reactor::run_event_loop ();
			ACE_Reactor::instance ()->run_reactor_event_loop ();
		}
#endif
	}
	else
	{
		if (ACE_Service_Config::open (argc, argv) == -1)
			ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t) %p\n", "DLL open"), 1);
		else
		{
			/**
			 * Setup signals for processing (must be after the open call in case of daemon)
			 */
			ACE_Sig_Adapter sa ((ACE_Sig_Handler_Ex) ACE_Reactor::end_event_loop);
			ACE_Sig_Set sig_set;
			sig_set.sig_add (SIGINT);
			sig_set.sig_add (SIGQUIT);
			sig_set.sig_add (SIGTERM);

			/**
			 *  Register to receive signals so we can shut down gracefully.
			 */
			if (ACE_Reactor::instance ()->register_handler (sig_set, &sa) == -1)
				ACE_ERROR ((LM_ERROR, "(%P|%t) %p\n", "register_handler"));
			else
			{
				//ACE_Reactor::run_event_loop ();
				ACE_Reactor::instance ()->run_reactor_event_loop ();
			}
		}
	}
	return 0;
}

