/* -*- C++ -*- */

/**
 *	@class Peer_Stdin_Handler
 *
 * 	@file  Peer_Stdin_Handler.h
 *
 * 	@brief Samson Factory Object
 *
 *	This object is used to ...
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef PEER_STDIN_HANDLER_H
#define PEER_STDIN_HANDLER_H

#include "ISE.h"

#include "ace/Service_Object.h"

namespace Samson_Peer {

class ISE_Export Peer_Stdin_Handler : public ACE_Service_Object
{
public:

	Peer_Stdin_Handler();

	virtual int handle_input (ACE_HANDLE);
	// The "True" method

	int (Peer_Stdin_Handler::*handle_input_)(ACE_HANDLE);
	int handle_simple_input (ACE_HANDLE);
	int handle_controller_input (ACE_HANDLE);
	// Process the command line inputs
};

}

#endif
