/**
 * @class EventChannel
 *
 * @brief Coordinates the Application with its Environment and Database
 *
 * This object is based on work by Doug Schmidt <schmidt@cs.wustl.edu>
 *
 * This defines a generic EventChannel, this is the central hub for
 * processing all events and maintaining connections
 *
 * The inspiration for this class is derived from the CORBA COS
 * (CORBA Event Channel), though the design is simplified.
 *
 * @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef _EVENT_CHANNEL_H
#define _EVENT_CHANNEL_H

#include "ISE.h"

#include "Peer_Connector.h" // NOTE: not using pointer or reference, so I need include
#include "DispatcherConfig.h"

#include "ace/Service_Config.h"
#include "ace/Event_Handler.h"
#include "ace/Singleton.h"
#include "ace/Null_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"


namespace Samson_Peer {

// forward declarations
class ConnectionHandler;

// ===========================================================================
class ISE_Export EventChannel
{
public:

	enum DispatcherRole { Node, Master };

	enum State {  Active = 0, Destroyed };

	// = Default Constructor/Destructor
	EventChannel ();
	~EventChannel ();

	// = Read Initialization method since is a Singleton
	int initialize();

	int open (void * = 0);
	// Open the channel.

	int destroy (u_long = 0);
	// Perform channel close down activities

	// = Proxy management methods.
	int initiate_connection (ConnectionHandler *, int sync_directly = 0);
	// Initiate the connection of the <ConnectionHandler> to its peer.
	// Second parameter is used for thread connection-handler which will
	// block the connecting procedure directly, need not care
	// Options::blocking_semantics().

	int reinitiate_connection (ConnectionHandler *);
	int reinitiate_connection (int);
	// Reinitiate a connection asynchronously when the Peer fails.

	int cancel_connection (ConnectionHandler *);
	// Cancel a asynchronous connection.

	//int find_entity (ACE_INT32 connection_id, SimEntity *&);
	// Locate the <SimEntity> with <connection_id>.

	bool isMaster(void) { return this->role_ == Master; }


	// = Event processing entry point.
	int process (
		ConnectionHandler *rh,
		ACE_Message_Block *mb,
		EventHeader *eh,
		ACE_Time_Value * = 0);

	int initiate_command_acceptor (void);
	// Put passive connectin into SimEntity Table for later listening on

	int initiate_connect (int port, const char* const host, const char* const name="Service");
	// Initiate an Active connection

	int initiate_d2d_connect (const char *host);
	// Initiate a Dispatcher to Dispatcher connection

	void initiate_all_d2d_connections (void);
	// Initiate connection to all other dispatchers

	const std::string compute_performance_statistics (int type);
	// Perform timer-based performance profiling.

	void print (void);

	bool anneal;  // temporary D2D test!!!!

protected:
	int parse_args (int argc, char *argv[]);
	// Parse the command-line arguments.

	Peer_Connector connector_;
	// Used to establish the connections actively.
	// This adds functionality...not data
	// TODO: Should it be here?

	DispatcherRole role_;
	// What is this ?

	ACE_Recursive_Thread_Mutex mutex_;
	// TODO:  document this

	State state_;
	// Used to ensure destroy is called
};

// =======================================================================
// Create a Singleton for the Application
// Manage this from DispatcherFactory::fini
typedef ACE_Unmanaged_Singleton<EventChannel, ACE_Recursive_Thread_Mutex> EVENT_CHANNEL_MGR;

} // namespace

#endif // _EVENT_CHANNEL_H

