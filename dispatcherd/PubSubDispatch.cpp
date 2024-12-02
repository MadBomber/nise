/**
 *	@file PubSubDispatch.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 *	@brief  Publish-Subscribe Dispatcher for Samson Header
 *
 */

#define ISE_BUILD_DLL

#include "PubSubDispatch.h"
#include "EventChannel.h"
#include "Service_ObjMgr.h"
#include "Options.h"
#include "IdentityTrace.h"
#include "DispatcherIdentity.h"
#include "auto.h"
#include "CommandParser.h"
#include "DebugFlag.h"
#include "SubscriptionCache.h"
#include "PeerRouteCache.h"
#include "LogLocker.h"
#include "TransmitHandler.h"

#include "ConnectionTable.h"
#include "ConnectionRecord.h"

#include <sstream>
#include <string>

#include <boost/lexical_cast.hpp>
#include <boost/lambda/lambda.hpp>
#include <boost/lambda/if.hpp>
#include <boost/lambda/bind.hpp>
#include <boost/range.hpp>

#include <boost/crc.hpp>  // for boost::crc_32_type


namespace Samson_Peer {


#if !defined (__ACE_INLINE__)
#include "PubSubDispatch.inl"
#endif /* __ACE_INLINE__ */

//............................................................................
PubSubDispatch::PubSubDispatch()
{
	ACE_TRACE("PubSubDispatch::PubSubDispatch");
}

//............................................................................
PubSubDispatch::~PubSubDispatch()
{
	ACE_TRACE("XMLParser::~PubSubDispatch");

	// Close out peer caching singleton
	PEER_ROUTE_SET::close();

#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~PubSubDispatch called.\n"));
#endif
}

//............................................................................
int PubSubDispatch::initialize()
{
	ACE_TRACE("PubSubDispatch::initialize");
	return 1;  // used in the EventChannel to initialize PubSubDispatch
}


// ==========================================================================
void
PubSubDispatch::process_hello_event (ConnectionHandler *rh, const SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::process_hello_event");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	// Create a Record, will be destroyed later
	ModelIdentityRecord entity;
	entity.chid = int(rh->get_handle ());
	entity.mid = sh->peer_id ();
	entity.ch = rh;


	// If it is a "model" that we are speaking to, then this logic holds

	if ( SAMSON_OBJMGR::instance()->getModelDetails (entity.mid, entity.mid_name,
			entity.jid, entity.nodeid,  entity.pid, entity.unitid, entity.statsid) )
	{
		if ( DebugFlag::instance ()->enabled (DebugFlag::ROUTE) )
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) PubSubDispatch::process_hello_event(%d|%x) -> MODEL chid=(%d|%x), modelID=%d (%s) jobid=%d, nodeid=%d, pid=%d, unitid=%d\n",
				rh->get_handle(), rh,
				entity.chid, entity.ch, entity.mid, entity.mid_name.c_str(),
				entity.jid, entity.nodeid,  entity.pid, entity.unitid));
		}

		// bind it into the table
		// TODO:  if already exists, do not bind
		bool bound = D2M_TABLE::instance()->bind(&entity);
		if (!bound)
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_ERROR,
				"(%P|%t) PubSubDispatch::process_hello_event(%d|%x) -> D2M_TABLE bind (%d) -> "
				"MODEL chid=(%d|%x), modelID=%d (%s) jobid=%d, nodeid=%d, pid=%d, unitid=%d\n",
				rh->get_handle(), rh,
				bound,
				entity.chid, entity.ch, entity.mid, entity.mid_name.c_str(),
				entity.jid, entity.nodeid,  entity.pid, entity.unitid));
			D2M_TABLE::instance()->print();
		}

		// Set the Model.DispatcherReady flag
		SAMSON_OBJMGR::instance()->setReady(entity.mid);
	}
	else if ( SAMSON_OBJMGR::instance()->isDispatcher(entity.mid,entity.nodeid) )
	{
		DispatcherIdentityRecord d_entity;
		d_entity.chid = int(rh->get_handle ());
		d_entity.peer = sh->peer_id ();
		d_entity.node = entity.nodeid;
		d_entity.ch = rh;

		if (DebugFlag::instance ()->enabled (DebugFlag::ROUTE))
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) PubSubDispatch::process_hello_event(%d|%x -> DISPATCHER chid=(%d|%x), PeerID=%d NodeID=%d\n",
				rh->get_handle(), rh,
				entity.chid, entity.ch, entity.mid, entity.nodeid));
			return;
		}

		D2D_TABLE::instance ()->bind(&d_entity);

	}
	else  // dispatcher logic ?? TODO needs to be flushed out
	{
		EVENT_CHANNEL_MGR::instance ()->print ();
	}

	return;
}


// ==========================================================================
/*
 * Note:  do not release the event or header
 */
int
PubSubDispatch::process (ConnectionHandler *rh, ACE_Message_Block *event, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::process");

#if 1
	// Potentially a valid event,  verify it
	ACE_UINT32 crc32 = 0;
	if (event && event->length() > 0)
	{
		boost::crc_32_type  result;
		result.process_bytes( event->base(),event->length() );
		crc32 = result.checksum();
		if ( sh->crc32() != crc32 )
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_ERROR, "(%P|%t) PubSubDispatch::process() -> CRC32 Checksum Error  %x != %x\n" ,sh->crc32(), crc32));

		}
	}
#endif

	if ( sh->enabled(SimMsgFlag::log_it) )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) PubSubDispatch::process() -> log_it: "));
		sh->print();
		if ( event ) ACE_LOG_MSG->log_hexdump (LM_DEBUG,(char *) event->rd_ptr(), event->length());
	}


	if (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) ||
			DebugFlag::instance ()->enabled (DebugFlag::PH_INPUT) ||
			IDENTITY_TRACE::instance ()->trace(sh->peer_id()) )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) PubSubDispatch::process(%d|%x) -> ", rh->get_handle(), rh ));
		sh->print();
	}

	// TODO  I really want to capture all hello events seperately (this is for now)
	if ( sh->type() == SimMsgType::HELLO)
	{
		//ACE_DEBUG ((LM_DEBUG, "hello\n"));
		this->process_hello_event (rh, sh);
	}
	else if ( sh->type() == SimMsgType::SUBSCRIBE)
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) PubSubDispatch::process(%d) -> SUBSCRIBE MESSGE DOES NOT WORK YET!\n",rh->get_handle()));
		sh->print();

	}
	else if ( sh->type() == SimMsgType::D2D_CONNECT)
	{
		EVENT_CHANNEL_MGR::instance ()->initiate_all_d2d_connections();
	}
	else if ( sh->type() == SimMsgType::GOODBYE)
	{
#if 0
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG,
			"(%P|%t) PubSubDispatch::process(%d)  GOODBYE -> Samson (Mdl:%d, Msg:%d(%d), type=%d, flags=%hx)\n",
			rh->get_handle(), sh->peer_id(), sh->message_id(), sh->app_msg_id(), sh->type(), sh->bit_flags() ));
#endif
		// The model is to be disconnected, this call will stop the reconnect process
		rh->commanded_close ();

		// returning -1 will cause a disconnect of this
		return -1;
	}
	else if ( sh->type() == SimMsgType::LOG_EVENT_CHANNEL_STATUS)
	{
		EVENT_CHANNEL_MGR::instance ()->print ();
		D2M_TABLE::instance()->print();
		// ACE_DEBUG ((LM_INFO,"%s\n", CONNECTION_TABLE::instance ()->status_connections().c_str()));
	}
	else if( sh->type() == SimMsgType::LOG_CHANNEL_STATUS )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_INFO,"%s\n", this->message_report(rh).c_str()));
	}
	else if ( sh->type() == SimMsgType::RECOVERABLE_ERROR_STATUS_RESPONSE ||
			sh->type() == SimMsgType::FATAL_ERROR_STATUS_RESPONSE ||
			sh->type() == SimMsgType::OK_STATUS_RESPONSE )
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) )
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_INFO, "(%P|%t) PubSubDispatch::process(%d) -> (Status Response) Samson (Mdl:%d, Msg:%d(%d), type=%d, flags=%hx, len=%d)\n",
					rh->get_handle(), sh->peer_id(), sh->message_id(), sh->app_msg_id(), sh->type(), sh->bit_flags(), sh->data_length() ));
		}

		if ( event && event->length() > 0)
		{
			ACE_UINT16 flags = sh->bit_flags ();

			// Log this on this dispatcher's local log
			if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_dispatcherd) )
			{
				LogLocker log_lock;
				std::string msg = std::string ( event->base(), event->length() );
				ACE_DEBUG ((LM_INFO,"%s\n", msg.c_str()));
			}

			// Relay this back to the "Command Channel" that requested it
			if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_sender) )
			{
				CommandParser::cmd_status ( sh->message_id(), event->duplicate () );
			}
		}
	}
	else
	{
#if 0
		if ( sh->type() == SimMsgType::STATUS_REQUEST || sh->type() == SimMsgType::GOODBYE_REQUEST )
 		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_INFO, "(%P|%t) PubSubDispatch::process(%d) ->"));
			sh->print();
		}
#endif

		//  Now look at the SimMsgFlag to Process
		//  TODO  Move this block to Samson_Dispatch
		if (sh->enabled (SimMsgFlag::master_only))  // send only to the Job Master
		{
			//ACE_DEBUG ((LM_DEBUG, "master\n"));
			this->route_to_master (rh, event, sh);
		}

		else if (sh->enabled (SimMsgFlag::p2p))  //  route to a peer
		{
			//ACE_DEBUG ((LM_DEBUG, "peer\n"));
			this->route_to_peer (rh, event, sh);
		}

		else if (sh->enabled (SimMsgFlag::job))  // send to all peers on this Job
		{
			unsigned int job_id = sh->run_id ();
			bool flush = ( sh->type() == SimMsgType::GOODBYE_REQUEST );

			//ACE_DEBUG ((LM_DEBUG, "all_job\n"));
			this->route_to_job (rh, event, sh);

			// The Goodbye Request is special whend sent to all peers in a job,
			// Clear out the query cache, and log the savings!
			if (flush)
			{
				SUBSCR_SET::instance ()->unbindRunID (job_id);
				PEER_ROUTE_SET::instance ()->unbindRunID (job_id);
			}
		}
		else if (sh->enabled (SimMsgFlag::p2ch))  // send to all peers on this Job
		{
			this->route_to_connection (rh, event, sh);
		}
		else if (sh->enabled (SimMsgFlag::nowhere))  // don't send on
		{
			// nothing to do
		}
		else //  route to subscribers
		{
			//ACE_DEBUG ((LM_DEBUG, "subscribers\n"));
			//PUBSUB_DISPATCH::instance ()->route_to_subscriber (event, sh);
			this->route_to_subscriber (rh, event, sh);
		}

}

	/*
	 * TODO evaluate the return, should I collect it for a lower level
	 *
	 * To continue smoothly a 0 should be returned, as it is at the end of the "RecieveHandler::handle_input" chain of calls
	 */
	return 0;
}

//...........................................................................
int
PubSubDispatch::send_ctrl_event (ConnectionHandler *ch, int type, bool master_only)
{
	ACE_TRACE("PubSubDispatch::send_ctrl_event");

	ACE_Guard<ACE_Recursive_Thread_Mutex> locker (mutex_);

	SamsonHeader *nsh = new SamsonHeader();

	// Note: these two together indicate we are a service, not a model
	nsh->run_id (0);
	nsh->peer_id (SAMSON_OBJMGR::instance()->ModelID());
	nsh->clear_flags ();
	nsh->type (type);
	nsh->data_length (0);

	if ( master_only) nsh->enable( SimMsgFlag::master_only );

	// Create a Record, will be destroyed later
	int HEADER_SIZE = nsh->header_length ();

	ACE_Message_Block *start_mb;
	ACE_NEW_RETURN (  start_mb,
		ACE_Message_Block (
			HEADER_SIZE,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
		Options::instance ()->locking_strategy ()),
	-1);

	nsh->encode();
	char const*temp = nsh->addr ();
	start_mb->copy(temp,HEADER_SIZE);

	if (ch->put (start_mb) == -1)
	{
		if (errno == EWOULDBLOCK) // The queue has filled up!
			ACE_ERROR ((LM_ERROR,
						"(%P|%t) (%P|%t) PubSubDispatch::send_ctrl_event -> %p\n",
						"gateway is flow controlled, so we're dropping events on %x:%d",
						ch, ch->get_handle()));
		else
			ACE_ERROR_RETURN ((LM_ERROR,
						"(%P|%t) (%P|%t) PubSubDispatch::send_ctrl_event -> %p transmission error to peer %x:%d\n",
						"put",
						ch, ch->get_handle()),
						-1);

		// If an error occured, we are responsible for cleaning up.
		start_mb->release();
	}
	return 0;
}


// ==========================================================================
// ==========================================================================
// ==========================================================================
// Process a routing event.

void
PubSubDispatch::route_to_subscriber (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::route_to_subscriber");

	SamsonTraceRecord trace_record;

	unsigned int job_id = sh->run_id();
	unsigned int sender_mid = sh->peer_id();
	unsigned int sender_uid = sh->unit_id();
	unsigned int msg_id = sh->message_id ();
	unsigned int app_msg_id = sh->app_msg_id();
	unsigned int msg_type = sh->type();
	unsigned int thisNode = SAMSON_OBJMGR::instance ()->NodeID ();

	bool local_only = sh->dispatched() != 0;

	int nsent = 0; // number of times the send method was invoked

	// This ensures we do not get loop-back
	sh->dispatched(1);

	// before header is encoded, see if we trace
	bool trace_it = (DebugFlag::instance ()->enabled (DebugFlag::ROUTE)
			|| IDENTITY_TRACE::instance ()->trace(sh->peer_id())
			);
	//trace_it = true;

	// debug tracing
	bool save_it = sh->enabled(SimMsgFlag::trace);
	if (save_it)
	{
		trace_record.sh_ = *sh;
		//trace_record.sh_.print();
	}


	// Encode the header for network byte ordering
	sh->encode();

	// Get all the local and remote destinations of this message.  This is is cached for the duration of the job
	std::vector<PeerRoute> local;
	std::vector<unsigned int> remote;
	SAMSON_OBJMGR::instance()->getAllSubscribers (job_id, msg_id, sender_uid, local, remote, trace_it);

	/**	The route will happen in two parts
	 *	1. local clients
	 *	2. remote dispatchers
	 */

	// Part 1.  Local
	{
		// loop over local subscribers
		for (size_t i=0; i<local.size(); ++i)
		{
			if (trace_it)
			{
				LogLocker log_lock;
				ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) PubSubDispatch::route_to_subscriber(local): msg=(%d:%d) mdl=%d-%d type=%d node=%d (%d of %d) -> mdl=%d node=%d\n",
					msg_id, app_msg_id, sender_mid, sender_uid, msg_type,
					thisNode,i,local.size(),
					local[i].peer_id, local[i].node_id ));
			}

			if (save_it) trace_record.sl_.push_back(local[i]);

			ConnectionHandler *ch  = D2M_TABLE::instance()->getCHfromModelID (local[i].peer_id);
			if ( ch )
			{
				nsent ++;
				TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
				if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
			}
			else  // True error, but all we can do is report it
			{
				LogLocker log_lock;
				std::string appKey = SAMSON_OBJMGR::instance()->getAppMsgKey(app_msg_id);
				std::string PeerKey = SAMSON_OBJMGR::instance()->getPeerKey(sender_mid);
				ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_subscriber(local): ERROR model=%d not found!\n",local[i].peer_id));
				ACE_DEBUG ((LM_ERROR,"   Error Details msg=(%d:%d-%s) model=(%d:%d-%s) type(%d) node(%d) cnt=%d\n",
						msg_id, app_msg_id, appKey.c_str() , sender_mid, sender_uid, PeerKey.c_str(), msg_type, thisNode, local.size()));

				// print the table we are looking in also
				// D2M_TABLE::instance()->print();

				// remove it to keep the error from occurring again
				SAMSON_OBJMGR::instance()->unsubscribe (local[i].peer_id, msg_id, sender_uid);
				SAMSON_OBJMGR::instance()->reset_cache ();
			}
		} // local subscribers loop
	}

	// Part 2. Remote
	if (!local_only)
	{
		if (trace_it)
		{
			if (remote.size() > 0 )
			{
				LogLocker log_lock;
				std::stringstream remotes;
				for (size_t i=0; i<remote.size(); ++i) remotes << remote[i] << " ";
				ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) PubSubDispatch::route_to_subscriber(remote): msg=(%d:%d) mdl=%d-%d node=%d -> to %d Nodes (%s)\n",
					msg_id, app_msg_id, sender_mid, sender_uid, thisNode, remote.size(), remotes.str().c_str()));
			}
		}

		for (size_t i=0; i<remote.size(); ++i)
		{
			if (save_it) trace_record.sr_.push_back(remote[i]);

			ConnectionHandler *ch = D2D_TABLE::instance ()->getCHfromNodeID(remote[i]);
			if ( ch )
			{
				nsent ++;
				TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
				if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
			}
			else  // this is an error, only print for now.
			{
				std::vector<PeerRoute> peer_sr;
				if ( SAMSON_OBJMGR::instance()->getNodeRoute (remote[i], peer_sr) != 1 )
				{
					LogLocker log_lock;
					ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_subscriber(remote): Remote Dispatcher not found %d\n",remote[i]));
					continue;
				}
			}

		} // Loop remote subscribers (via their dispatcher)
	}

	if (nsent==0)
	{
		LogLocker log_lock;
		std::string appKey = SAMSON_OBJMGR::instance()->getAppMsgKey(app_msg_id);
		std::string PeerKey = SAMSON_OBJMGR::instance()->getPeerKey(sender_mid);
		ACE_DEBUG ((LM_ERROR,
			"(%P|%t) PubSubDispatch::route_to_subscriber: job(%d) msg(%d:%d- %s) mdl(%d:%d - %s) on node %d -> Not Sent\n",
			job_id, msg_id, app_msg_id, appKey.c_str(), sender_mid, sender_uid, PeerKey.c_str(), thisNode
		));
	}

	if (save_it)
	{
		msg_trace_.add(rh,&trace_record);
		//this->msg_trace_.print(rh);
	}

}



// ==========================================================================
// Process a routing event.

void
PubSubDispatch::route_to_master (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::route_to_master");

	ACE_UNUSED_ARG (rh);

	unsigned int jobid = sh->run_id ();
	unsigned int sender_mid = sh->peer_id();
	unsigned int sender_uid = sh->unit_id();
	unsigned int msg_id = sh->message_id ();
	unsigned int app_msg_id = sh->app_msg_id();
	unsigned int msg_type = sh->type();
	unsigned int thisNode = SAMSON_OBJMGR::instance ()->NodeID ();

	// This ensures we do not get loop-back
	sh->dispatched(1);

	// before header is encoded, see if we trace
	bool trace_it = (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) || IDENTITY_TRACE::instance ()->trace(sh->peer_id()));

	// Encode the header for network byte ordering
	sh->encode();

	//  this should be only in the "master_only" subsection, but I need to figure out the "all" first.
	std::vector<PeerRoute> master_sr;
	if ( SAMSON_OBJMGR::instance()->getJobMaster (jobid, master_sr) != 1 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_master -> No Master found for Job = %d\n", jobid));
		return;
	}

	ConnectionHandler *ch = 0;

	if ( ((master_sr[0].node_id  == thisNode) &&  (ch = D2M_TABLE::instance()->getCHfromModelID(master_sr[0].peer_id))) ||
					(ch=D2D_TABLE::instance ()->getCHfromNodeID(master_sr[0].node_id)))
	{
		if (trace_it)
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,
					"Samson Route (master):: msg_id=%d app_msg_id=%d mid=%d uid=%d type=%d on node %d  -> to mid: %d on node %d flag %d\n",
					msg_id, app_msg_id, sender_mid, sender_uid, msg_type, thisNode,
					master_sr[0].peer_id, master_sr[0].node_id, true));
		}
		TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
		if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
	}
	else
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_master -> no route for msg_id=%d app_msg_id=%d mid=%d uid=%d type=%d on node %d\n",
			msg_id, app_msg_id, sender_mid, sender_uid, msg_type, thisNode));
	}
}

// ==========================================================================
// Process a routing event.

void
PubSubDispatch::route_to_peer (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::route_to_peer");

	ACE_UNUSED_ARG (rh);

	SamsonTraceRecord trace_record;

	unsigned int jobid = sh->run_id ();
	unsigned int sender_mid = sh->peer_id();
	unsigned int sender_uid = sh->unit_id();
	unsigned int msg_id = sh->message_id ();
	unsigned int app_msg_id = sh->app_msg_id();
	unsigned int msg_type = sh->type();
	unsigned int thisNode = SAMSON_OBJMGR::instance ()->NodeID ();
	unsigned int dest_peer_id = sh->dest_peer_id();

	// This ensures we do not get loop-back
	sh->dispatched(1);

	// before header is encoded, see if we trace
	bool trace_it = (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) || IDENTITY_TRACE::instance ()->trace(sh->peer_id()));

	// debug tracing
	bool save_it = sh->enabled(SimMsgFlag::trace);
	if (save_it)
	{
		trace_record.sh_ = *sh;
	}

	// Encode the header for network byte ordering
	sh->encode();

	//bool sendit = false;

	std::vector<PeerRoute> peer_sr;
	SAMSON_OBJMGR::instance()->getPeerRoute (jobid, dest_peer_id, peer_sr, trace_it);

	if ( peer_sr.size() != 1 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_peer -> Error in Peer Route Dst=%d, Src=%d\n", dest_peer_id, sender_mid));
		return;
	}

	ConnectionHandler *ch = 0;

	if ( ((peer_sr[0].node_id  == thisNode) && (ch = D2M_TABLE::instance ()->getCHfromModelID ( peer_sr[0].peer_id))) ||
					(ch=D2D_TABLE::instance ()->getCHfromNodeID(peer_sr[0].node_id)))
	{
		if (trace_it)
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,
					"(%P|%t) PubSubDispatch::route_to_peer -> msg=(%d:%d) mdl=%d-%d type=%d on node %d  -> to mdl=%d node=%d flag %d\n",
					msg_id, app_msg_id, sender_mid, sender_uid, msg_type, thisNode,
					peer_sr[0].peer_id, peer_sr[0].node_id, true));
		}

		if (save_it) trace_record.sl_.push_back(peer_sr[0]);

		TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
		if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
	}
	else
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_peer -> no route for msg_id=%d app_msg_id=%d mid=%d uid=%d type=%d dest_mid=%d on node %d with ch=%x\n",
			msg_id, app_msg_id, sender_mid, sender_uid, msg_type, dest_peer_id, thisNode, ch));

		peer_sr[0].print ();
		if (peer_sr[0].node_id  == thisNode) D2M_TABLE::instance ()->print ();
		else D2D_TABLE::instance ()->print ();
	}

	if (save_it)
	{
		msg_trace_.add(rh,&trace_record);
	}

}

// ==========================================================================
// Process a routing event.

// This ONLY works for a peer on this dispatcher!!!!

void
PubSubDispatch::route_to_connection (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::route_to_connection");

	ACE_UNUSED_ARG (rh);

	SamsonTraceRecord trace_record;

	//unsigned int jobid = sh->run_id ();
	unsigned int sender_mid = sh->peer_id();
	//unsigned int sender_uid = sh->unit_id();
	//unsigned int msg_id = sh->message_id ();
	//unsigned int app_msg_id = sh->app_msg_id();
	//unsigned int msg_type = sh->type();
	//unsigned int thisNode = SAMSON_OBJMGR::instance ()->NodeID ();

	// This field is overloaded, in this case it is the channel_id to be used
	unsigned int dest_conn_id = sh->dest_peer_id();

	// This ensures we do not get loop-back
	sh->dispatched(1);

	// before header is encoded, see if we trace
	//bool trace_it = (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) || IDENTITY_TRACE::instance ()->trace(sh->peer_id()));

	// debug tracing
	bool save_it = sh->enabled(SimMsgFlag::trace);
	if (save_it)
	{
		trace_record.sh_ = *sh;
	}

	// Encode the header for network byte ordering
	sh->encode();

	// get the connection Record
	ConnectionRecord *con_rec = 0;
	if ( (con_rec = CONNECTION_TABLE::instance ()->find(dest_conn_id)) == 0 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_ERROR,"(%P|%t) PubSubDispatch::route_to_connection -> Error in Finding Connection Record Dst=%d, Src=%d\n", dest_conn_id, sender_mid));
		return;
	}


	std::set<ConnectionHandler *>::iterator it;
	for ( it=con_rec->ch_set_.begin(); it != con_rec->ch_set_.end(); it++ )
	{
		ConnectionHandler *ch = *it;
		TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
		if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
	}


	if (save_it)
	{
		msg_trace_.add(rh,&trace_record);
	}

}

// ==========================================================================
// Process a routing event.

void
PubSubDispatch::route_to_job (ConnectionHandler *rh, ACE_Message_Block *data, SamsonHeader *sh)
{
	ACE_TRACE("PubSubDispatch::route_to_job");

	ACE_UNUSED_ARG (rh);

	unsigned int jobid = sh->run_id ();
	unsigned int sender_mid = sh->peer_id();
	unsigned int sender_uid = sh->unit_id();
	unsigned int msg_id = sh->message_id ();
	unsigned int app_msg_id = sh->app_msg_id();
	unsigned int msg_type = sh->type();
	unsigned int thisNode = SAMSON_OBJMGR::instance ()->NodeID ();

	bool local_only = sh->dispatched() != 0;

	// This ensures we do not get loop-back
	sh->dispatched(1);

	// before header is encoded, see if we trace
	bool trace_it = (DebugFlag::instance ()->enabled (DebugFlag::ROUTE) || IDENTITY_TRACE::instance ()->trace(sh->peer_id()));
	//trace_it = true;

	// Encode the header for network byte ordering
	sh->encode();

	AUTO(p,D2M_TABLE::instance()->allRecordsInJob(jobid));
	for(AUTO(it,p.first); it!=p.second; ++it)
	{
		TransmitHandler *th = dynamic_cast<TransmitHandler *>(it->ch);
		if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));

		if (trace_it)
		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG,
					"Samson Route (job-local):: msg_id=%d app_msg_id=%d mid=%d uid=%d type=%d on node %d  -> to mid: %d on chid %d \n",
					msg_id, app_msg_id, sender_mid, sender_uid, msg_type, thisNode, it->mid, it->chid));
		}
	}


	// send to all connecting Dispatchers which have a member of this job_id
	if (!local_only)
	{
		std::vector<unsigned int> dispatchers;
		int ndis = SAMSON_OBJMGR::instance()->getOtherDispatchers (dispatchers);
		for (int i=0; i<ndis; ++i)
		{
			if (trace_it)
			{
				LogLocker log_lock;
				ACE_DEBUG ((LM_DEBUG,
					"Samson Route (job-remote):: msg_id=%d app_msg_id=%d mid=%d uid=%d type=%d on node %d (%d of %d) -> to node %d",
					msg_id, app_msg_id, sender_mid, sender_uid, msg_type, thisNode,
					i,ndis, dispatchers[i]));
			}

			if ( ConnectionHandler *ch = D2D_TABLE::instance ()->getCHfromNodeID(dispatchers[i]) )
			{
				TransmitHandler *th = dynamic_cast<TransmitHandler *>(ch);
				if (th!=0) th->put (data, dynamic_cast<EventHeader *>(sh));
				if (trace_it)
				{
					LogLocker log_lock;
					ACE_DEBUG ((LM_DEBUG," (sent)\n"));
				}
			}
			else
				if (trace_it)
				{
					LogLocker log_lock;
					ACE_DEBUG ((LM_DEBUG," (ch==0?)\n"));
				}

		}
	}

}



} // namepsace
