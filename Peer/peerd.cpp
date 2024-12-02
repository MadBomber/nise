/*
	This is the standard main, one day it will allow us to move to a container based system

	Jack Lavender  February 2006

*/

#include "ace/OS_NS_unistd.h"
#include "Peer_Factory.h"

using namespace Samson_Peer;

int
ACE_TMAIN (int argc, ACE_TCHAR *argv[])
{
	// Turn off Tracing for now, re-evaluate this later
	ACE_Trace::stop_tracing();

	if (ACE_OS::access (ACE_DEFAULT_SVC_CONF, F_OK) != 0)
	{
		// Use static linking.
		ACE_Service_Object_Ptr sp = ACE_SVC_INVOKE (Peer_Factory);

		if (sp->init (argc - 1, argv + 1) == -1)
		    ACE_ERROR_RETURN ((LM_ERROR,
		                       ACE_TEXT ("%p\n"),
		                   ACE_TEXT ("init")),
		                      1);

		// Run forever, performing the configured services until we are
		// shut down by a SIGINT/SIGQUIT signal.

		ACE_Reactor::instance ()->run_reactor_event_loop ();

		// Destructor of <ACE_Service_Object_Ptr> automagically will call <fini>.
	}
	else
	{
		if (ACE_Service_Config::open (argc, argv) == -1)
			ACE_ERROR_RETURN ((LM_ERROR,
	                       ACE_TEXT ("%p\n"),
	                       ACE_TEXT ("open")),
	                      1);
		else // Use dynamic linking.

			// Run forever, performing the configured services until we
			// are shut down by a signal (e.g., SIGINT or SIGQUIT).

			ACE_Reactor::instance ()->run_reactor_event_loop ();
	}
	return 0;
}
