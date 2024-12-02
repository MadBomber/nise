/**
 *      @file EventChannel.cpp
 *
 *      @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *      This is derived from the ACE Gateway Example Application
 *
 */

#define ISE_BUILD_DLL

#include "EventChannel.h"
#include "ConnectionHandler.h"
#include "TransmitHandler.h"
#include "SamsonHeader.h"
#include "Service_ObjMgr.h"
#include "Peer_Acceptor.h"
#include "ConnectionTable.h"
#include "EventHeader.h"
#include "PubSubDispatch.h"
#include "XMLParser.h"
#include "Options.h"
#include "IdentityTrace.h"
#include "CommandParser.h"
#include "CommandIdentity.h"
#include "DispatcherIdentity.h"
#include "ModelIdentity.h"
#include "DebugFlag.h"
#include "LogLocker.h"
#include "ChannelFilterMgr.h"

#include <vector>

#include "ace/OS_NS_sys_select.h"
#include "ace/Signal.h"



namespace Samson_Peer {


//......................................................................
EventChannel::EventChannel() : state_(Active)
{
	ACE_TRACE("EventChannel::EventChannel");
	this->anneal = false;
}

//......................................................................
EventChannel::~EventChannel()
{
	ACE_TRACE("EventChannel::~EventChannel");
	if ( state_ != Destroyed )  this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~EventChannel called at %T.\n"));
#endif
}

// =====================================================================
// This is the the real constructor!!

int
EventChannel::initialize ()
{
	ACE_TRACE ("EventChannel::initialize");

	// Ignore <SIGPIPE> so each Receiving Handler can process it.
	ACE_Sig_Action sig ((ACE_SignalHandler) SIG_IGN, SIGPIPE);
	ACE_UNUSED_ARG (sig);

#if 0
	// If we're not running reactively, then we need to make sure that
	// <ACE_Message_Block> reference counting operations are
	// thread-safe.  Therefore, we create an <ACE_Lock_Adapter> that is
	// parameterized by <ACE_SYNCH_MUTEX> to prevent race conditions.
	if (Options::instance ()->threading_strategy () != Options::REACTIVE)
	{
		ACE_Lock_Adapter<ACE_SYNCH_MUTEX> *la;
		ACE_NEW_RETURN (la, ACE_Lock_Adapter<ACE_SYNCH_MUTEX>, -1);
		Options::instance ()->locking_strategy (la);
	}
#endif

	/**
	 *  Initialize the Channel Filter Manager ;
	 */
	if (CH_FILTER_MGR::instance ()->initialize() < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t|%T) Flter Manger Singleton failed to initialize\n"),
				-1);
	}

	/**
	 *  Initialize CONNECTION_TABLE;
	 */
	else if (CONNECTION_TABLE::instance()->initialize() < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t|%T) CONNECTION_TABLE Singleton failed to initialize\n"),
				-1);
	}
	else if (PUBSUB_DISPATCH::instance()->initialize() < 0)
	{
		ACE_ERROR_RETURN((LM_ERROR,
				"(%P|%t|%T) CONNECTION_TABLE Singleton failed to initialize\n"),
				-1);
	}

	// One dispatcher needs to be the master...  This concept needs flushing out
	this->role_ = SAMSON_OBJMGR::instance()->isMasterDispatcher() ? EventChannel::Master : EventChannel::Node;


	if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) EventChannel::initialize -> Dispatcher Role=%d \n",this->role_));

	return 1;
}

// ==========================================================================
// ==========================================================================

const std::string
EventChannel::compute_performance_statistics (int type)
{
#if 0
	if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) EventChannel::compute_performance_statistics\n"));
#endif

	// Iterate through the connection map summing up the number of bytes
	// sent/received.

	// TBD:  how does this work with threading ?

	const std::string my_report = CONNECTION_TABLE::instance ()->compute_stats(type);


	return my_report;
}


// ==========================================================================
int
EventChannel::initiate_connection (
	ConnectionHandler *ch,
	int sync_directly)
{
	ACE_TRACE ("EventChannel::initiate_connection");

#if 0
	ACE_DEBUG ((LM_DEBUG,
		"(%P|%t|%T) EventChannel::initiate_connection(%0x)\n", ch));
#endif


	ACE_Synch_Options synch_options;

	if (sync_directly)
		// In separated connection handler thread, connection can be
		// initiated by block mode (synch mode) directly.
		synch_options = ACE_Synch_Options::synch;

	else if (Options::instance ()->blocking_semantics () == ACE_NONBLOCK)
		synch_options = ACE_Synch_Options::asynch;

	else
		synch_options = ACE_Synch_Options::synch;

	return this->connector_.initiate_connection (ch, synch_options);
}

// ==========================================================================
// Restart connection (blocking_semantics dicates whether we restart
// synchronously or asynchronously).

int
EventChannel::reinitiate_connection (ConnectionHandler *ch)
{
	ACE_TRACE ("EventChannel::reinitiate_connection (ch)");

	int result = 0;

#if 0
	ACE_DEBUG ((LM_DEBUG,
		"(%P|%t|%T) EventChannel::reinitiate_connection(%d)|0x%x|%d)\n",
		ch->get_handle(), ch, ch->connection_id ()));
#endif

	// Cancel asynchronous connecting before re-initializing.  It will
	// close the peer and cancel the asynchronous connecting.
	this->cancel_connection(ch);

	if (ch->state () != ConnectionHandler::DISCONNECTING)
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t|%T) EventChannel::reinitiate_connection(1) -> scheduling reinitiation of CID(%d)\n",
				ch->connection_id ()));
		}

		// Reschedule EventChannel::initiate_connection to try and connect again.
		result = ch->schedule_reconnect ();
	}
	return result;
}


// ===========================================================================
int
EventChannel::reinitiate_connection (int cid)
{
	ACE_TRACE ("EventChannel::reinitiate_connection (cid)");

	int result = 0;
	ConnectionRecord *entity = CONNECTION_TABLE::instance ()->find (cid);

	// entity does not exist
	if (entity == 0 ) return -1;

	//  This is an active connection, it should only have ONE connection_handler
	//....none is a serious error in ACE
	//....more than one is just a damn programming error on my part
	if ( entity->ch_set_.size() != 1)
		ACE_ERROR_RETURN ((LM_ERROR,
			"(%P|%t|%T) EventChannel::reinitiate_connection(2) -> bad connection_handler size (%d)\n",
			entity->ch_set_.size()),
			-1);

	//....just in case....reset em all!!!!

	std::set<ConnectionHandler *>::iterator it;
	for ( it=entity->ch_set_.begin() ; it != entity->ch_set_.end(); it++ )
	{
		// Reset the timeout to 1.
		(*it)->timeout (1);
		result = (*it)->close();
	}

	// this return value may be bogus
	return result;
}


// ===========================================================================
// It is useful to provide a separate method to cancel the
// asynchronous connecting.

int
EventChannel::cancel_connection ( ConnectionHandler *ch)
{
	ACE_TRACE ("EventChannel::cancel_connection");

	int result = -1;

	// Skip over proxies with deactivated handles.
	if ( ch->get_handle () != ACE_INVALID_HANDLE)
	{
		if ( !ch->passive() ) result = this->connector_.cancel(ch);
	}
	else if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
	{
		LogLocker log_lock;

		ACE_DEBUG((LM_DEBUG,"(%P|%t|%T) EventChannel::cancel_connection() -> Invalid Handle(%d).\n",ch->get_handle()));
	}

	return result;
}


// ==========================================================================
// Initiate passive acceptor (Listener)

int
EventChannel::initiate_command_acceptor (void)
{
	ACE_TRACE ("EventChannel::initiate_command_acceptor");

	// Create a holder for the Command Channel
	ConnectionRecord *entry = new ConnectionRecord;
	entry->id_ = 0; // dynamic assignment
	entry->name_ = "cmd listener";
	entry->header_ = "none";
	entry->max_retry_timeout_ = Options::instance ()->max_timeout ();
	entry->priority_ = 0;
	entry->proxy_role_ = 'C';
	entry->connection_type_ = 'P';
	entry->host_ = "0.0.0.0";
	entry->port_ = Options::instance ()->command_port ();
	entry->peer_acceptor_ = 0;
	entry->isMaster_ = false;
	entry->tcp_nodelay = true;
	entry->send_buff = 0;
	entry->recv_buff = 0;
	entry->read_buff = 0;
	entry->input_filter_ = "";
	entry->output_filter_ = "";

	// Bind this as a possible entry
	CONNECTION_TABLE::instance ()->bind (entry);
	return 0;
}

// ==========================================================================
// Initiate active connection (Connector)

int
EventChannel::initiate_connect (int port, const char * const host, const char * const name)
{
	ACE_TRACE ("EventChannel::initiate_connect");

	// Create a holder for the Command Channel
	ConnectionRecord *entry = new ConnectionRecord;
	entry->id_ = 0; // dynamic assignment
	entry->name_ = name;
	entry->header_ = "samson";
	entry->max_retry_timeout_ = Options::instance ()->max_timeout ();
	entry->priority_ = 0;
	entry->proxy_role_ = 'B';
	entry->connection_type_ = 'A';
	entry->host_ = host;
	entry->port_ = port;
	entry->peer_acceptor_ = 0;
	entry->isMaster_ = false;
	entry->tcp_nodelay = true;
	entry->send_buff = 0;
	entry->recv_buff = 0;
	entry->read_buff = 0;
	entry->input_filter_ = "";
	entry->output_filter_ = "";

	// Bookkeeping
	CONNECTION_TABLE::instance ()->bind (entry);

	// Connect
	CONNECTION_TABLE::instance ()->initiate_connection (entry);

	return 0;
}


// ==========================================================================
// Initiate active dispatcher to dispatcher connection (Connector)

int
EventChannel::initiate_d2d_connect (const char *host)
{
	ACE_TRACE ("EventChannel::initiate_d2d_connect");

	unsigned short port = Options::instance ()->d2d_port ();
	this->initiate_connect (port, host, "d2d");

	// ACE_DEBUG((LM_DEBUG,"(%P|%t|%T) EventChannel::initiate_d2d_connect() -> %s:%d  (out)\n",host,port));

	return 0;
}


// ==========================================================================
//

void
EventChannel::initiate_all_d2d_connections (void)
{
	ACE_TRACE ("EventChannel::initiate_all_d2d_connections");

	DispatcherIdentityRecord entity;
	int ncon_made = 0; // number of connections made
	int ndis = 0; // number of other dispatchers

	std::vector<unsigned int> dispatchers;

	if ( (ndis = SAMSON_OBJMGR::instance ()->getHigherDispatchers (dispatchers)) < 1 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_INFO,"(%P|%t|%T) EventChannel::initiate_all_d2d_connection -> No other dispatchers found\n"));
		return;
	}

	for ( int i=0; i<ndis; i++)
	{
		// ... check to see if already connected
		if ( D2D_TABLE::instance ()->findNodeID ( dispatchers[i], &entity) ) continue;

		{
			std::string ip;
			std::string fqdn;
			if ( SAMSON_OBJMGR::instance ()->DispatcherInfo(dispatchers[i], ip, fqdn))
				EVENT_CHANNEL_MGR::instance ()->initiate_d2d_connect(ip.c_str());
		}
		ncon_made++;
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_INFO,"(%P|%t|%T) EventChannel::initiate_all_d2d_connection -> Complete! (%d)\n",ncon_made));
	}
	return;
}

// ==========================================================================
// ==========================================================================
// ==========================================================================
// ==========================================================================
// This method gracefully shuts down all the Handlers in the
// ConnectionHandler Connection Map.

int
EventChannel::destroy (u_long)
{
	ACE_TRACE ("EventChannel::destroy");

#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) EventChannel Destroy Started at %T.\n"));
#endif

	// Stop any attempts to create an active connection
	this->connector_.close();

	// Release the mapping table singletons
	D2M_TABLE::close();
	D2D_TABLE::close();
	D2C_TABLE::close();

	// There is no specific initialize for the Publish/Subscribe singleton, but it claims memory
	PUBSUB_DISPATCH::close();

	// Now tell connections that it is now time to commit suicide.
	// Since all connections are part of the SystemEntityTable, let it do the work.
	CONNECTION_TABLE::close ();

	// Filters should have already been taken care of, but just in case
	CH_FILTER_MGR::close();

	// Close out the identity tracing singleton
	IDENTITY_TRACE::close();

#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) EventChannel Destroy Completed at %T\n"));
#endif

	this->state_ = Destroyed;
	return 0;
}




// ===========================================================================
// ===========================================================================
int
EventChannel::open (void *)
{
	ACE_TRACE ("EventChannel::open");

	int result = 0;

	// Open up a command_channel
	if (this->initiate_command_acceptor () != 0) result = -1;

	// initiate Peer connections both Active and Passive.
	if (CONNECTION_TABLE::instance ()->initiate_connections () != 0) result = -1;

	return result;
}





// ===========================================================================
// ===========================================================================
// ===========================================================================
// ===========================================================================
// ==========================================================================
//	This is the event_processing section


// this needs to return 0 to continue

//TODO:  get this back to all Message Blocks, if we thread the processing this will
//be where they should be allocated from.

// ==========================================================================
// ==========================================================================
int
EventChannel::process (
	ConnectionHandler *rh,  // really a ReceiveHandler
	ACE_Message_Block *event,
	EventHeader *eh,
	ACE_Time_Value *tv)
{
	ACE_TRACE("EventChannel::process");

	ACE_UNUSED_ARG(tv);
	//static int cnt = 0;

	int result = 0;

	// To route we may require the connection_id
	if ( eh->connection_id() == 0 )
	{
		eh->connection_id(rh->connection_id());
	}


	if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) (start) EventChannel::process(%d|0x%x) -> Header(CID=%d type=%x Hex=%s)\n",
			rh->get_handle(), rh, eh->connection_id(), eh->header_type(), eh->gethex()
		));
	}


	/*
	 *  Delegate the processing elsewhere
	 */

	// Process command channel
	if ( rh->command_role() || eh->type() == SimMsgType::DISPATCHER_COMMAND)
	{
		if ( eh->type() == (int) SimMsgType::XML_COMMAND )
		{
			//ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) EventChannel::process ->XML Command\n"));
			result = XML_PARSER::instance()->process(rh, event, eh);
		}
		else
		{
			DebugFlag::instance ()->enable (DebugFlag::CMD_DEBUG);
			ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) EventChannel::process -> Command\n"));
			result = COMMAND_PARSER::instance ()->process (rh, event);
		}
	}

	// this is an echo channel
	else if ( rh->proxy_role() == 'E' )
	{
		if ( strncmp(event->base(),"disconnect",10) == 0 )
		{
			rh->commanded_close ();
			result = -1;
		}
		else // echo it to all connected to this channel
		{
			int cid = eh->connection_id();
			ConnectionRecord *entity = CONNECTION_TABLE::instance ()->find (cid);

			std::set<ConnectionHandler *>::iterator it;
			for ( it=entity->ch_set_.begin() ; it != entity->ch_set_.end(); it++ )
			{
				if ( (*it) != rh )
				{
					TransmitHandler *th = dynamic_cast<TransmitHandler *>(*it);
					if (th!=0) th->put(event, eh);  // send release the message
				}
			}
		}

	}

	// Process Samson Events!
	else if ( eh->header_type() ==  EventHeader::SAMSONHEADER )
	{
		SamsonHeader *sh  = dynamic_cast<SamsonHeader *>(eh);

		if ( IDENTITY_TRACE::instance ()->trace(sh->peer_id()))
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) (start) EventChannel::process(%d) -> Header(CID=%d type=%x Hex=%s)\n",
				rh->get_handle(), eh->connection_id(), eh->header_type(), eh->gethex()));
			sh->print();
		}

//		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) EventChannel::process(%d) -> Samson (peer_id=%d, msg_id=%d, app_msg_id=%d, type=%d, flags=%hx)\n",
//			rh->get_handle(), sh->peer_id(), sh->message_id(), sh->app_msg_id(), sh->type(), sh->bit_flags() ));

		result = PUBSUB_DISPATCH::instance()->process(rh, event, sh);
	}
#if 1
	else
	{
		// TODO, log this properly
		LogLocker log_lock;

		ACE_DEBUG ((LM_ERROR, "(%P|%t|%T) (start) EventChannel::process(%d) NOT CAUGHT-> Header(CID=%d type=%x size=%d Hex=%s)\n",
				rh->get_handle(), eh->connection_id(), eh->header_type(), eh->data_length(), eh->gethex()));
		eh->print();
	}
#endif


	// These were allocated in the receive, hopefully all will come back nice and tidy!
#if 1
	if ( event )
	{
		if ( event->reference_count() != 1 )
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) (end) EventChannel::process(%d|0x%x) Event Release not complete --> %d\n",
					rh->get_handle(), rh, event->reference_count()));
		}
		event->release();
	}
	else if ( eh->data_length() >0 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) (end) EventChannel::process(%d|0x%x) Event Released Prior!!!\n",
				rh->get_handle(), rh));
		SamsonHeader *sh  = dynamic_cast<SamsonHeader *>(eh);
		sh->print ();

	}
#else
	//  Optimistic code ;)
	if ( event ) event->release();
#endif

	delete eh;

	if (DebugFlag::instance ()->enabled (DebugFlag::CHANNEL))
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T) (end) EventChannel::process(%d|0x%x) Complete --> result=%d\n", rh->get_handle(), rh, result));
	}

	return result;
}

void
EventChannel::print (void)
{
	ACE_DEBUG ((LM_DEBUG, "(%P|%t|%T)\n%s\n%s\n%s\n%s",
			(SAMSON_OBJMGR::instance ()->report ()).c_str(),
			(CONNECTION_TABLE::instance ()->status_acceptors()).c_str(),
			(CONNECTION_TABLE::instance ()->status_connections()).c_str(),
			(CONNECTION_TABLE::instance ()->print_ctable()).c_str()
	));

	DebugFlag::instance ()->print();
}

} // namespace
