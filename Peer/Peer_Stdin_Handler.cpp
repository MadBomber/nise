/* -*- C++ -*- */

/**
 * 	@file  Peer_Stdin_Handler.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "Peer_Stdin_Handler.h"

#include "ace/Reactor.h"

//#include "Options.h"
#include "DebugFlag.h"
#include "Model_ObjMgr.h"
#include "SharedAppMgr.h"
#include "SimMsgType.h"
#include "SamsonPeerData.h"

namespace Samson_Peer {

// ........................................................................................
/**
 * This assigns the proper STDIN intepretor.
 *
 * No Desctructor is required as we are not allocating
 */
Peer_Stdin_Handler::Peer_Stdin_Handler() : ACE_Service_Object ()
{
	/*
	this->handle_input_ = &Peer_Stdin_Handler::handle_simple_input;
	if (Options::instance ()->enabled (Options::CONTROLLER))
		this->handle_input_ = &Peer_Stdin_Handler::handle_controller_input;
	*/
}

/**
 * 
 * @param h 
 * @return 
 */
int
Peer_Stdin_Handler::handle_input (ACE_HANDLE h )
{
	return (this->*handle_input_)(h);
}

// ........................................................................................
int
/**
 * 
 * @param h 
 * @return 
 */
Peer_Stdin_Handler::handle_simple_input (ACE_HANDLE h)
{
	int retval = 0;
	char buf[BUFSIZ], *pbuf, *cmd;

    // Print a menu
	//ACE_DEBUG((LM_DEBUG, ">>" ));

    // Consume the input...
	ssize_t n = ACE_OS::read (h, buf, sizeof buf - 1);

	if (n > 1)
	{
	        // Null terminate the buffer, replacing the '\n' with '\0'.
		if (buf[n - 1] == '\n' || buf[n - 1] == EOF)
			buf[n - 1] = '\0';
		else
			buf[n] = '\0';

		cmd = ACE_OS::strtok_r (buf, " \t",&pbuf);
				
        //ACE_DEBUG ((LM_DEBUG, "Read From stdin %s\n", buf));
		if ( cmd != 0 )
		{
			switch (cmd[0])
			{	
				case 'j':
				{
					SAMSON_OBJMGR::instance ()->print ();
					retval = 1;
				}
				break;
	
				case 'p':
				{
					char *a;
					if ( (a = ACE_OS::strtok_r (0, " \t",&pbuf)) == 0 )
						SAMSON_APPMGR::instance()->print_map_all ();
					else
					{
						SAMSON_APPMGR::instance()->print_map_entry ( atoi(a) );
					}
					retval = 1;
				}
				break;

				case 'q':
				{
					ACE_Reactor::instance ()->end_reactor_event_loop ();
					retval = -1;
				}
				break;
	
				case 'v':
				{
					if (DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
						DebugFlag::instance ()->disable(DebugFlag::VERBOSE);
					else
						DebugFlag::instance ()->enable(DebugFlag::VERBOSE);
				}
				break;


				default:
				{
					//ACE_DEBUG ((LM_DEBUG, "Read From stdin %s\n", buf));
					retval = n;
				}
			}
		}
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
		ACE_DEBUG ((LM_DEBUG, "Peer_Stdin_Handler::handle_simple_input(%d) -> retval %d\n", h, retval));

	return 0;  // override retval, must return 0 !!!
}

// ........................................................................................
/**
 * 
 * @param h 
 * @return 
 */
int
Peer_Stdin_Handler::handle_controller_input (ACE_HANDLE h)
{
	int retval = 0;
	char buf[BUFSIZ], *pbuf, *cmd;

	// Print a menu
	ACE_DEBUG((LM_DEBUG, "Enter a command (m - menu):\n" ));

    // Consume the input...
	ssize_t n = ACE_OS::read (h, buf, sizeof buf - 1);

	if (n > 1)
	{
        // Null terminate the buffer, replacing the '\n' with '\0'.
		if (buf[n - 1] == '\n' || buf[n - 1] == EOF)
			buf[n - 1] = '\0';
		else
			buf[n] = '\0';

		cmd = ACE_OS::strtok_r (buf, " \t",&pbuf);
				
        //ACE_DEBUG ((LM_DEBUG, "Read From stdin %s\n", buf));
		if ( cmd != 0 )
		{
			switch (cmd[0])
			{
				case 'c':
				{
					char *a;
					if ( (a = ACE_OS::strtok_r (0, " \t",&pbuf)) == 0 )
						ACE_DEBUG ((LM_DEBUG, ACE_TEXT ("must enter an integer\n")));
					else
					{
						int msg = atoi(a);
						int flag = 0x0;
						if ( (a = ACE_OS::strtok_r (0, " \t",&pbuf)) != 0 )  flag = atoi(a);
						// ACE_DEBUG ((LM_DEBUG, "Header Flag = %d\n",flag));
						SAMSON_APPMGR::instance()->sendCtrlMsg ( msg, flag );
					}
					retval = 1;
				}
				break;

				case 'h':
				{
					SAMSON_APPMGR::instance()->sendCtrlMsg (SimMsgType::HELLO);
					retval = 1;
				}
				break;
	
				case 'j':
				{
					SAMSON_OBJMGR::instance ()->print ();
					retval = 1;
				}
				break;
	
				case 'K':
				{
					SAMSON_APPMGR::instance()->sendCtrlMsg (SimMsgType::END_SIMULATION);
					retval = 1;
				}
				break;
	
				case 'p':
				{
					char *a;
					if ( (a = ACE_OS::strtok_r (0, " \t",&pbuf)) == 0 )
						SAMSON_APPMGR::instance()->print_map ();
					else
					{
						SAMSON_APPMGR::instance()->print_map_entry ( atoi(a) );
					}
					retval = 1;
				}
				break;

				case 'P':
				{
					SamsonPeerData *spd = 0;
					int n_spd = SAMSON_OBJMGR::instance ()->getRunPeerList(spd);
					for (int i=0; i<n_spd; ++i) spd[i].print();
					delete[] spd;
				}
				break;

				case 'q':
				{
					ACE_Reactor::instance ()->end_reactor_event_loop ();
					retval = -1;
				}
				break;
		
				case 'v':
				{
					if (DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
						DebugFlag::instance ()->disable(DebugFlag::VERBOSE);
					else
						DebugFlag::instance ()->enable(DebugFlag::VERBOSE);
				}
				break;

				case 'm':
				default:
				{
					// Print a menu
					ACE_DEBUG((LM_DEBUG,
						"\tc # - send a control message (see SimMsgType.h)\n"
						"\th - send a hello to all the dispatcher (not that usefl\n"
						"\tj - Samson Object Manager Data\n"
						"\tK - send end simulation to all\n"
						"\tp - display process 'publish' table\n"
						"\tP - display process 'peer' table\n"
						"\tr - display list of peers\n"
						"\tv - turn on/off verbose printing  (%s)\n"
						"\tq - exit the program\n",
						DebugFlag::instance ()->enabled (DebugFlag::VERBOSE)?"ON":"OFF"
						));
				}
				break;

			}
		}
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::VERBOSE))
		ACE_DEBUG ((LM_DEBUG, "Peer_Stdin_Handler::handle_controller_input(%d) -> retval %d\n", h, retval));

	return 0;  // override, must return 0
}


}
