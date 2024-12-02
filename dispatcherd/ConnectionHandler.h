/**
 *	@file ConnectionHandler.h
 *
 *	@class ConnectionHandler
 *
 *	@brief Logic to process an active or passive connection
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#ifndef _CONNECTION_HANDLER_H
#define _CONNECTION_HANDLER_H

#include "ISE.h"
#include "EventHeaderFactory.h"
#include "RouterStats.h"
#include "Reaction.h"
#include "ConnectionRecord.h"
#include "auto.h"
#include "DispatcherConfig.h"
#include "FilterBase.h"


#include "ace/Service_Config.h"
#include "ace/config-all.h"
#include "ace/Svc_Handler.h"
#include "ace/INET_Addr.h"
#include "ace/SOCK_Connector.h"
#include "ace/Svc_Handler.h"
#include "ace/Lock_Adapter_T.h"
#include "ace/Synch_Traits.h"
#include "ace/Thread_Mutex.h"
#include "ace/Recursive_Thread_Mutex.h"


// Boost Serialization
#include <boost/serialization/string.hpp>
#include <boost/serialization/utility.hpp>
#include <boost/serialization/version.hpp>
#include <boost/serialization/serialization.hpp>



namespace Samson_Peer {

// forward declarations
//class ConnectionRecord;

class ISE_Export ConnectionHandler : public ACE_Svc_Handler<ACE_SOCK_STREAM, ACE_MT_SYNCH>
{
	// = TITLE
	//     <ConnectionHandler> contains info about connection state and
	//     addressing.
	//
	// = DESCRIPTION
	//     The <ConnectionHandler> classes process events sent to the
	//     Event Channel.

public:

	// Constructor
	ConnectionHandler () : entity_(0), input_filter_(0), output_filter_(0), state_(UNINITIALIZED) {}

	// Real constructor!
	int initialize (ConnectionRecord * const);

	// void destructor
	virtual ~ConnectionHandler ();

	// = The current state of the ConnectionHandler.
	enum State
	{
		UNINITIALIZED,	// initialize has not been called.
		IDLE,			// initialized and ready to be used.
		CONNECTING,		// During connection establishment.
		ESTABLISHED,	// ConnectionHandler is established and active.
		DISCONNECTING,	// ConnectionHandler is in the process of connecting.
		FAILED			// ConnectionHandler has failed.
	};

	// = Initialize and activate a single-threaded <ConnectionHandler>
	virtual int open (void * = 0);

	// = (override) Perform timer-based ConnectionHandler reconnection.
	virtual int handle_timeout (const ACE_Time_Value &, const void *arg);

	// = (override) Perform ConnectionHandler termination.
	virtual int handle_close (ACE_HANDLE = ACE_INVALID_HANDLE,
                            ACE_Reactor_Mask = ACE_Event_Handler::ALL_EVENTS_MASK);

	// = handles connection failure  (default!)
	virtual int handle_input(ACE_HANDLE);

	// = complete connection, partially moved from Event Channel
	int complete_connection (void);

	// = Turn on the commanded_close
	void commanded_close(void) { commanded_close_ = true; }

	/*
	 *  Handler had only one header!
	 */

	// Factory to Create a Header
	EventHeaderFactory EVH;

	// = Create this kind of header based on another.
	EventHeader *create_header(EventHeader *eh);

	/*
	 * Status and Reporting
	 */

	// = Print status information
	virtual void status (std::stringstream &, bool);

	// = Calculate and Print the current stats
	void stats(std::stringstream &, bool, int);

	// =Calculate and save the current stats
	void save_stats (unsigned int job_id, unsigned int peer_id);

	// = Calculate total number of bytes sent/received on this proxy.
	inline void total_bytes_send (size_t bytes);
	inline void total_bytes_recv (size_t bytes);

	// = TODO define what a reaction set does

	// = Add a Reaction to the set
	inline void register_reaction (Reaction *);

	// = Remove a Reaction from the set
	inline void remove_reaction (Reaction *);


	/*
	 *  Connection options
	 */

	// = Get the Connection Role.
	inline char proxy_role (void) const;

	// = Is the Connection Role "Command" ?
	inline bool command_role (void) const;

	// = Get the Connection Type.
	inline char connection_type (void) const;

	// = Get the Read Buffer Size.
	unsigned int read_buff (void) const;

	// = Sets the connection retry timeout
	void timeout(unsigned int to);

	// = Schdule reconnection
	int schedule_reconnect (void);

	// = Set the send/receive buffer sizes.
	void set_buffer_sizes (void);

	// = Turn off the no-delay flag.
	void set_nodelay (void);

	// = Is this an active(connector) or passive(acceptor) connection
	inline bool passive(void);

	// = Set/get remote INET addr.
	inline const ACE_INET_Addr &remote_addr (void) const;
	inline void remote_addr (ACE_INET_Addr &ra);

	// = Set/get local INET addr
	inline const ACE_INET_Addr &local_addr (void) const;
	inline void local_addr (ACE_INET_Addr &la);

	// = Set/Get the state of the Proxy.
	inline void state (ConnectionHandler::State s);
	inline State state (void) const;

	// = Gets the connection header id.
	inline int header_type_id (void) const;

	// = Get the Connection ID
	inline ACE_INT32 connection_id (void) const;

	// = Gets the max timeout delay.
	inline unsigned int max_timeout (void) const;

	// = Gets the first message alert logical .
	inline bool first_message_alert (void) const;

	// = Calculates the current retry timeout
	unsigned int timeout (void);

	// = Encodes and trasmits message out
	//virtual int put (ACE_Message_Block *event, EventHeader *eh) { return 0; }

	// = Used by boost serialzation to save/restore one of these!
	template<class Archive>
	void serialize(Archive & ar, const unsigned int /* file_version */)
	{
	  AUTO(handle,get_handle());
	  std::string local_addr(local_addr_.get_host_addr());
	  std::string remote_addr(remote_addr_.get_host_addr());
	  unsigned short local_port(local_addr_.get_port_number());
	  unsigned short remote_port(remote_addr_.get_port_number());

	  using boost::serialization::make_nvp;
		ar
		& make_nvp("connection_id"   , connection_id_)
		& make_nvp("handle"          , handle)
		& make_nvp("local_address"   , local_addr)
		& make_nvp("local_port"      , local_port)
		& make_nvp("remote_address"  , remote_addr)
		& make_nvp("remote_port"     , remote_port)
		& make_nvp("connection_type" , entity_->connection_type_)
		& make_nvp("proxy_role"      , entity_->proxy_role_)
		& make_nvp("state"           , state_)
		& make_nvp("input_filter_"   , input_filter_dll_)
		& make_nvp("output_filter_"  , output_filter_dll_)
		;
	}

	// ----------------------------------------------------------------
protected:

	const ConnectionRecord * entity_;
	// Used to access the provisioning information for this connection

	FilterBase *input_filter_;
	FilterBase *output_filter_;
	// Filters

	std::string input_filter_dll_;
	std::string output_filter_dll_;
	// Filter DLL names

	ACE_INET_Addr remote_addr0_;
	ACE_INET_Addr remote_addr_;
	// Address of peer.

	ACE_INET_Addr local_addr_;
	// Address of us.

	ACE_INT32 connection_id_;
	// The assigned connection ID of this handler.

	State state_;
	// The current state of the proxy.

	unsigned int timeout_;
	// Amount of time to wait between reconnection attempts.

	long timer_id_;
	// Used to cancel any pending connection timer

	int header_type_id_;
	// Reference to the <EventHeader> that will be read/created for this message

	Reaction_Set active_reaction_list_;
	//  This is an unbounded set of Registered Reactions for THIS handler.
	//  Reactions are used to perform side-effects for incoming/outging  messages.
	//  I am setting this for Control Channels....but not restricting its use.

	bool commanded_close_;
	// commanded close flag;

	// ==================================================================
	// = Utilization Collection section

	RouteByteStats send_stats;
	RouteByteStats recv_stats;
	RouteTimeStats process_time;

	ACE_Recursive_Thread_Mutex mutex_;
	// TODO:  document this
};

} // namespace

// TODO does not work, revisit later!

#if defined (__ACE_INLINE__)
#include "ConnectionHandler.inl"
#endif


#endif /* _CONNECTION_HANDLER_H */
