/* -*- C++ -*- */

/**
 *	@file SharedAppMgr.cpp
 *
 *	@brief Provide an interface with a Shared Object (dll or so)
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */


#define ISE_BUILD_DLL

#include <sstream>


#include <boost/crc.hpp>  // for boost::crc_32_type

// ...........................................................................
#include "ace/SString.h"
#include "ace/Dynamic_Service.h"

#include "SharedAppMgr.h"
#include "Peer_Handler.h"

#include "AppBase.h"
#include "MessageBase.h"
#include "Model_ObjMgr.h"
#include "Options.h"
#include "DebugFlag.h"
#include "SamsonPeerData.h"

#define STATUS_MESSAGE_MAX_LENGTH 2048

// ===========================================================================
// ===========================================================================
// ===========================================================================
namespace Samson_Peer {

// ===========================================================================
// Static initialization.
SharedAppMgr *SharedAppMgr::instance_ = 0;

// ===========================================================================
/**
 * Return Singleton.
 *
 * @param  None
 * @return The address of the Option object
 */
SharedAppMgr *
SharedAppMgr::instance (void)
{
  if (SharedAppMgr::instance_ == 0)
    ACE_NEW_RETURN (SharedAppMgr::instance_, SharedAppMgr, 0);

  return SharedAppMgr::instance_;
}

// ===========================================================================
/**
 * Object Constructor
 *
 * The constructor sets the current state to inactive and initializes
 * the message maps for regular messages and control messages.
 *
 * @return  No return
 */
SharedAppMgr::SharedAppMgr()
{
	ACE_TRACE("SharedAppMgr::SharedAppMgr");

	this->State=inactive;
	this->app_ = 0;

	// Size the Ace_Maps to a reasonable initial size
	this->map_.open(20);
}

// ===========================================================================
/**
 * Called from Peer_Factory during initialization
 *
 * This registers the Peer Handler then
 * opens/initializes the Samson Model Shared Library
 *
 * @param peer The Peer Handler used to send/recv data
 * @param argc Command line argument count
 * @param argv[] Command line arguments
 *
 * @return  1 for success, -1 for failure
 */
int
SharedAppMgr::init(Peer_Handler *peer, AppBase *eap, int argc, ACE_TCHAR *argv[])
{
	ACE_TRACE("SharedAppMgr::init");

	int retval = -1;

	/// Set the Peer Handler
	this->peer_ = peer;
	if (peer)
	{
		this->peer_->register_application(this);
		this->State = active;

		if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
		{
			ACE_DEBUG((LM_DEBUG,"(%P|%t) SharedAppMgr::init()-> Peer official name: %s (%s)\n",
			SAMSON_OBJMGR::instance()->hostname (),SAMSON_OBJMGR::instance()->ipaddress ()));
			ACE_DEBUG((LM_DEBUG,"%P|%t)SharedAppMgr::init()-> Running Model.ID = %d for Job.id = %d on Node.id = %d\n\n",
				SAMSON_OBJMGR::instance()->ModelID(),
				SAMSON_OBJMGR::instance()->RunID(),
				SAMSON_OBJMGR::instance()->NodeID()));
		}


		// If we are embdded in the "model" we cannot open it up!!!
		// This was done for Randy Kassner's MASES
		if ( !Options::instance ()->enabled (Options::EMBEDDED))
		{
			ACE_CString adll = SAMSON_OBJMGR::instance ()->AppLib ();
			ACE_CString directive = ACE_CString("dynamic ");
			directive += adll;
			directive += ACE_CString(" Service_Object * ");
			directive += adll;
			directive += ACE_CString(":_make_");
			directive += adll;
			directive += ACE_CString("() active \"");
			for (int i=0; i<argc; i++)
				directive += ACE_CString(argv[i]) +  ACE_CString(" ");
			directive += ACE_CString("\"");

			if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
			{
				ACE_DEBUG((LM_DEBUG,"(%P|%t) SharedAppMgr::init() -> %s\n",directive.c_str()));
				ACE::debug(true);
			}
			ACE_Service_Config::process_directive (directive.c_str());
			retval = ACE_Service_Config::instance ()->find ( adll.c_str(), 0, 0);

			if (retval != -1) this->app_ = ACE_Dynamic_Service<AppBase>::instance (adll.c_str());
			ACE::debug(false);
		}
		else
		{
			this->app_ = eap;
			retval = this->app_ ->init(argc, argv);
		}
	}

	this->app_timer_.start();

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) || retval == -1)
	{
		ACE_DEBUG((LM_DEBUG,"(%P|%t) SharedAppMgr::init() -> %d\n",retval));
	}

	return retval;
}

// ===========================================================================
/**
 *
 * @param cnt
 * @return
 */
SamsonPeerData *
SharedAppMgr::getRunPeerList(int &cnt)
{
	SamsonPeerData *spd = 0;
	cnt = SAMSON_OBJMGR::instance ()->getRunPeerList(spd);
	return spd;
}

// ===========================================================================
/**
 * This sets the Peer_Handler for the AppMgr
 *
 * This is not currently used, I am not sure this should stay around.
 * It is better to set that handler during init() phase.
 *
 * @param peer  pointer to the Peer_Handler
 */
void
SharedAppMgr::handler_set(Peer_Handler *peer)
{
	ACE_TRACE("SharedAppMgr::handler_set");

	this->peer_ = peer;
	this->peer_->register_application(this);

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
	{
		ACE_DEBUG((LM_DEBUG,"(%P|%t) SharedAppMgr::handler_set()\n"));
	}
}

// ===========================================================================
/** Object Destructor
 *
 * If the Samson Application Manager is in an active state,
 * then this will first clean up.
 *
 * @return no return
 */
SharedAppMgr::~SharedAppMgr()
{
	ACE_TRACE("SharedAppMgr::SharedAppMgr");

	if (this->State==active)
	{
		//if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
			ACE_DEBUG((LM_INFO,"(%P|%t) SharedAppMgr::close()\n"));
		this->close ();
	}

}

// ===========================================================================
/**
 * This takes the header and data in a MessageBlock chain and send it using
 * the associated Peer_Handler
 *
 * @param str_msg
 * @param sh
 * @return
 */
int
SharedAppMgr::publish (const std::string &str_msg, SamsonHeader *sh)
{
	ACE_TRACE("SharedAppMgr::publish (string)");


	// Work with character pointer
	const char *msg = str_msg.c_str();
	int len = str_msg.length();

	// Allocate a new Message_Block for sending this message
	ACE_Message_Block *data_mb =
		new ACE_Message_Block (
			len,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
			0);

	if (data_mb == 0 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SharedAppMgr::publish() -> Data Messsage_Block Allocation Error\n"), -1);

	// copy the data into the message block  (costly?)  !!! this sets the mb length!!!!!
	if ( data_mb->copy(msg,len) == -1 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SharedAppMgr::publish() -> Data Copy Error\n"), -1);

	// Debug output
	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
	{
		ACE_DEBUG ((LM_DEBUG,
					"(%P|%t)  SharedAppMgr::publish (CID = %d len= %d Hex =%s)\n",
					sh->connection_id (),
					sh->data_length (),
					sh->gethex ()));
		sh->print ();
	}

	//......finish the sending
	return this->publish(data_mb,sh);

}
// ===========================================================================
/**
 * This takes the header and data in a MessageBlock chain and send it using
 * the associated Peer_Handler
 *
 * @param data_mb
 * @param sh
 * @return
 */
int
SharedAppMgr::publish(ACE_Message_Block *data_mb, SamsonHeader *sh)
{
	ACE_TRACE("SharedAppMgr::publish");


	////////////////////////////////////////
	// Add send specific information

	static unsigned int send_count = 0;
	sh->send_count(send_count++); // count the number of messages this peers has sent

	ACE_UINT32 crc32 = 0;
	if (data_mb && data_mb->length() > 0)
	{
		boost::crc_32_type  result;
		result.process_bytes( data_mb->base(), data_mb->length() );
		crc32 = result.checksum();
		//ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::publish() -> CRC32 Checksum = %x\n",crc32));
	}
	sh->crc32(crc32);


	///////////////////////////////////////
	// Debug output

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) ||
		DebugFlag::instance ()->enabled (DebugFlag::PH_OUTPUT) )
	{
		ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::publish() -> "));
		sh->print ();
	}

	bool log_it = sh->enabled(SimMsgFlag::log_it);
	if (log_it)
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::publish() -> log_it: "));
		sh->print();
	}

	/////////////////////////////////////////
	//  Keep a history for tracing
	send_cb_.push_front(*sh);
	if ( send_cb_.size() > 10 ) send_cb_.pop_back();

	////////////////////////////////////////////
	// Encode the header for transmission
	// NOTE:  header not usable after this call
	sh->encode();

	// transfer the data into the outgoing message block
	char const *temp = sh->addr ();
	size_t HEADER_SIZE = sh->header_length ();

	// Allocate the header message block and chain the data to it.
	ACE_Message_Block *start_mb = 0;
	start_mb =  new
			ACE_Message_Block (
			HEADER_SIZE,
			ACE_Message_Block::MB_DATA,
			data_mb,
			0,
			0,
			0);


	if (start_mb == 0 )
		ACE_ERROR_RETURN (
				(LM_ERROR,
				 "(%P|%t) SharedAppMgr::publish() -> Header Messsage_Block Allocation Error\n"),
	-1);

	// Copy the header into the message block  (costly?)
	if ( start_mb->copy(temp,HEADER_SIZE) == -1 )
		ACE_ERROR_RETURN (
				(LM_ERROR,
				 "(%P|%t) SharedAppMgr::publish() -> Data Copy Error\n"),
	-1);


	// Free the Samson Header memory
	delete sh;

	// Let Peer_Handler transmit the data
	int result = this->peer_->transmit (start_mb,log_it);

	return result;
}

// ===========================================================================
/**
 * This will remove the application from our space and free the tables.
 *
 * @param  none
 * @return 1 = success
 */
int
SharedAppMgr::close(void)
{
	ACE_TRACE("SharedAppMgr::close");

	// Compute the time the DLL took to complete
	ACE_hrtime_t measured;
	this->app_timer_.stop();
	this->app_timer_.elapsed_microseconds (measured);
	double interval_sec = measured*1.0e-6;
	SAMSON_OBJMGR::instance ()->saveExecuteTime (interval_sec);

	// call the fini ????
	if (this->app_) this->app_->fini ();

	// Unload the DLL
	ACE_CString adll = SAMSON_OBJMGR::instance ()->AppLib ();
	ACE_CString directive = ACE_CString("remove ") + adll;
	ACE_Service_Config::process_directive (directive.c_str());


	// Empty the maps (good houskeeping!)
	this->map_.unbind_all ();

	// Set the State flag
	this->State = inactive;

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
	{
		ACE_DEBUG((LM_INFO,"(%P|%t) SharedAppMgr::close()\n"));
	}

	return 1;
}








// ===========================================================================
/**
 * This is called to dispatch the event to the applicaton
 *
 * NOTE:  This ONLY handles Samson Events!
 *
 * Called by Peer_Handler::await_events  down stream of the handle_input
 * The only significant return is <0,  that closed down the connection.
 *
 * @param mb The message data stored in an ACE Message Block
 * @param sh The SamsonHeader of the message
 * @return 0 for sucess, -1 for failure;
 */
int
SharedAppMgr::handle_event ( ACE_Message_Block *mb, const SamsonHeader *sh)
{
	ACE_TRACE("SharedAppMgr::handle_event");

	int retval = 0;

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event(%D) ->"));
		sh->print ();
	}

	if ( sh->enabled(SimMsgFlag::log_it) )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event -> log_it: "));
		sh->print();
	}

	// store the last events for debug purposes
	recv_cb_.push_front(*sh);
	if ( recv_cb_.size() > 10 ) recv_cb_.pop_back();


	//	==================================================
	//  Process a goodbye request, which terminates the model.
	if ( sh->type() == SimMsgType::GOODBYE_REQUEST )
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
			ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::handle_event(%D) - GOODBYE_REQUEST Message\n"));

			if ( this->app_ )
				this->app_->closeSimulation ();  // the controller is the intended target
			else
				 ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event(%D) - Kassner ??\n"));
	}

#if 0
	//	==================================================
	//  GOODBYE  (call the fini) TODO Question why here ??
	else if ( sh->type() == SimMsgType::GOODBYE )
	{
		this->app_->fini ();
	}
#endif

	//	==================================================
	// The dispatcher initiates the communications with a "Hello" Event, which evokes a "Hello" response.
	// This is how ALL  models and services need to introduce themselves
	else if ( sh->type() == SimMsgType::HELLO )
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
			ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::handle_event(%D) - HELLO Message\n"));

		// Returns HELLO!
		this->sendCtrlMsg (SimMsgType::HELLO);

		if ( this->app_ )
			this->app_->helloResponse ();  // the controller is the intended target
		else
			 ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event(%D) - Kassner ??\n"));
	}

	//	==================================================
	// Process a status request
	else if ( sh->type() == SimMsgType::STATUS_REQUEST )
	{
		if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
			ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::handle_event(%D) - STATUS_REQUEST Message\n"));


		if ( this->app_ )
		{
			// this interface is is fixed by the ACE Interface :(
			ACE_TCHAR *msg = 0;
			this->app_->info (&msg, STATUS_MESSAGE_MAX_LENGTH);

			std::stringstream my_status;
			my_status << msg << std::endl << this->print_send_list ()->str () <<  std::endl << this->print_recv_list ()-> str ();

			Samson_Peer::SAMSON_OBJMGR::instance ()->extendedStatus(my_status);

			ACE_UINT16 flags = sh->bit_flags ();

			if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_local) || DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG) )
			{
				ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event: status (%d)\n%s\n\n",
						my_status.str().length(),
						my_status.str().c_str()
				));
			}

			if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_dispatcherd) || ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_sender) )
			{
				ACE_UINT16 oflag = SimMsgFlag::nowhere;
				if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_dispatcherd)) oflag |= SimMsgFlag::status_log_dispatcherd;
				if ( ACE_BIT_ENABLED (flags, SimMsgFlag::status_log_sender)) oflag |= SimMsgFlag::status_log_sender;

				this->sendMsg (SimMsgType::OK_STATUS_RESPONSE, my_status.str(), oflag, sh->message_id() );
			}
			ACE::strdelete(msg);

			// this->sendCtrlMsg (SimMsgType::LOG_CHANNEL_STATUS);

		}
		else
			this->sendCtrlMsg (SimMsgType::RECOVERABLE_ERROR_STATUS_RESPONSE);
	}


	//	==================================================
	//  All other messages are registered to be processed.
	//
	//  Notes:  messages are told to "handle" the event.  This detaches the
	//	processing from loaded library code (using functors).
	//  Now we need to prepare for "framed" messages, which means storing them until
	//  the proper frame......hmmmmmm

	else
	{
#if 0
		if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
			ACE_DEBUG ((LM_INFO, "(%P|%t) SharedAppMgr::handle_event(%D) - OTHER Message\n"));
#endif


		// Data Messages can be queued, all other must be processes
		if ( sh->type() != SimMsgType::DATA  ||
				( sh->type() == SimMsgType::DATA && sh->enabled(SimMsgFlag::control) ) ||
				( sh->type() == SimMsgType::DATA && this->app_->data_ready() )
			)
		{
			//ACE_DEBUG ((LM_DEBUG, "D-q(%d): ", this->q_.size() ));
			//sh->print();

			this->handoff_event(mb,sh);
		}
		else // queue it
		{

			// TODO:  do the reference counting trick on the header!
			SamsonHeader *xsh = new SamsonHeader();
			*xsh = *sh;
			ACE_Message_Block *xmb = 0;
			if (mb) xmb = mb->clone();

			SamsonEvent se = SamsonEvent(xmb,xsh);
			this->q_.push(se);

			//ACE_DEBUG ((LM_DEBUG, "Q-q(%d): ", this->q_.size() ));
			//sh->print();
		}

		// Process Data Messages (a non-data message can open it up!)
		if ( !this->q_.empty() && this->app_->data_ready() )
		{
			while (!this->q_.empty()) {

				SamsonEvent se = this->q_.top();

				//ACE_DEBUG ((LM_DEBUG, "P-q(%d): ", this->q_.size() ));
				//se.sh_->print();

				this->handoff_event(se.mb_,se.sh_);
				delete se.sh_;
				if (se.mb_) se.mb_->release();
				this->q_.pop();
			}

		}
	}


	//  =================================================
	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG)  )
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handle_event(%D) -> returns %d with queue size=%d\n", retval, this->q_.size()));
	}

	return retval;
}


// ===========================================================================
int
SharedAppMgr::handoff_event (ACE_Message_Block *mb, const SamsonHeader *sh)
{
#if 0
	if ( this->app_->current_frame() != sh->frame_count()  &&
			this->app_->current_frame() != 0 &&
			sh->type() == SimMsgType::DATA
			/* sh->type() != SimMsgType::ADVANCE_TIME_REQUEST */)
	{
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::handoff_event: frame miss-match (%d)\n", this->app_->current_frame() ));
		//sh->print();
	}
	//sh->print();
#endif

	int retval = 0;
	MessageBase *sam_msg = 0;

	if ( this->map_.find (sh->app_msg_id (), sam_msg) == 0 )
	{
		//ACE_Trace::start_tracing();
		retval = sam_msg->handle_event (mb, sh);
		//ACE_Trace::stop_tracing();
	}
	else
	{
		ACE_DEBUG ((LM_ERROR, "(%P|%t) SharedAppMgr::handle_event(%D) -> (NOT FOUND)\n"));
		sh->print();
	}

	return retval;
}



















// ===========================================================================
/**
 * The application wants to register to process a message. This message
 * has the "process()" function
 *
 * @param appMsgID This is the Model Specific Massage ID, NOT the Samson Msg ID
 * @param msgHandler The handerler
 * @return 0 for success, -1 for failure, 0 for duplicate (TODO Verfy this)
 */
int
SharedAppMgr::registerProcess (int appMsgID, MessageBase *msgHandler )
{
	ACE_TRACE("SharedAppMgr::registerProcess");

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
	{
		ACE_DEBUG((LM_DEBUG,"(%P|%t) SharedAppMgr::registerProcess(%d) [Message is subscribing]\n",appMsgID));
		msgHandler->print();
	}

	return this->map_.bind (appMsgID, msgHandler);
}

// ===========================================================================
/**
 * The application wants to unregister to handle a "Control Message"
 * See SimMsgType.h for the Enumerations
 *
 * @param appMsgID
 * @return
 */
int
SharedAppMgr::unregisterProcess (int appMsgID )
{
	ACE_TRACE("SharedAppMgr::unregisterProcess");

	if (DebugFlag::instance ()->enabled (DebugFlag::APPMGR_DEBUG))
	{
		ACE_DEBUG((LM_DEBUG,"SharedAppMgr::unregisterProcess(%d)\n",appMsgID));
	}

	MessageBase *msgHandler = 0;
	return this->map_.bind (appMsgID, msgHandler);
}

// ===========================================================================
/**
 *
 * @param
 */
void
SharedAppMgr::print_map_all (void)
{
	ACE_TRACE("SharedAppMgr::print_map_all");

	this->print_map();

	ProcessMapIterator end = this->map_.end ();
	for (ProcessMapIterator iter = this->map_.begin ();
			iter != end;
			++iter)
	{
		this->print_map_entry( (*iter).ext_id_ );
	}
}

// ===========================================================================
/**
 *
 * @param
 */
void
SharedAppMgr::print_map (void)
{
	std::stringstream theMap;

	ProcessMapIterator end = this->map_.end ();
	for (ProcessMapIterator iter = this->map_.begin ();
			iter != end;
			++iter)
	{
/*
		theMap << (*iter).prev_
						<< "<-(" << (*iter).ext_id_
						<< " | " <<  std::hex << (*iter).int_id_
						<< ")->" << (*iter).next_
						<< std::endl;
*/
		theMap << std::dec << (*iter).ext_id_ << " -> " << std::hex << (*iter).int_id_ << std::endl;
	}

	ACE_DEBUG ((LM_DEBUG, "(%P|%t) SharedAppMgr::print_map\n"
		"The ProcessMap has %d members with alloated size of %d members\n%s",
		this->map_.current_size(),this->map_.total_size(), theMap.str().c_str() ));
}

// ===========================================================================
/**
 *
 * @param msg_id
 */
boost::shared_ptr<std::stringstream>
SharedAppMgr::print_send_list (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::list<SamsonHeader>::iterator i;

	for(i=send_cb_.begin(); i != send_cb_.end(); ++i)
	{
		*my_report << ">> " << (*i).report() << std::endl;
	}

	return my_report;
}

// ===========================================================================
/**
 *
 * @param none
 */
boost::shared_ptr<std::stringstream>
SharedAppMgr::print_recv_list (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::list<SamsonHeader>::iterator i;

	for(i=recv_cb_.begin(); i != recv_cb_.end(); ++i)
	{
		*my_report << "<< " << (*i).report() << std::endl;
	}

	return my_report;
}


// ===========================================================================
/**
 *
 * @param msg_id
 */
void
SharedAppMgr::print_map_entry (int msg_id)
{
	MessageBase *msg = 0;

	if ( this->map_.find (msg_id, msg) == 0 )
	{
		msg->print ();
	}
	else
	{
		ACE_DEBUG ((LM_ERROR, "(%P|%t) SharedAppMgr::print_map_entry msg_id (%d) was not found?\n", msg_id));
	}

}

// ===========================================================================
// ===========================================================================
// ===========================================================================
// ===========================================================================
// ===========================================================================
// ===========================================================================
/**
 * This sends a dataless Samson Control Message
 *
 * @param type The control message type @see SimMsgType.h
 * @param flag The control message flags @see SimMsgFlag.h
 */
int
SharedAppMgr::sendCtrlMsg (int type, unsigned short flag)
{
	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (SAMSON_OBJMGR::instance()->RunID());
	sh->peer_id (SAMSON_OBJMGR::instance()->ModelID());
	sh->message_id (0);
	sh->app_msg_id (0);
	sh->unit_id (SAMSON_OBJMGR::instance()->UnitID());
	sh->type (type);
	sh->bit_flags(flag);
	sh->frame_count(0);
	sh->send_count(0);
	sh->data_length (0);

	return this->publish ( (ACE_Message_Block *) 0, sh);
}

// ===========================================================================
/**
 * This sends a Samson Command Message
 *
 * @param type The control message type @see SimMsgType.h
 * @param flag The control message flags @see SimMsgFlag.h
 */
int
SharedAppMgr::sendCmdMsg (const std::string &str_msg)
{
	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (SAMSON_OBJMGR::instance()->RunID());
	sh->peer_id (SAMSON_OBJMGR::instance()->ModelID());
	sh->message_id (0);
	sh->app_msg_id (0);
	sh->unit_id (SAMSON_OBJMGR::instance()->UnitID());
	sh->type (SimMsgType::DISPATCHER_COMMAND);
	sh->bit_flags(SimMsgFlag::nowhere);
	sh->frame_count(0);
	sh->send_count(0);
	sh->data_length (str_msg.length());

	return this->publish (str_msg, sh);
}

// ===========================================================================
/**
 * This sends a Samson Message
 *
 * @param type The control message type @see SimMsgType.h
 * @param flag The control message flags @see SimMsgFlag.h
 */
int
SharedAppMgr::sendMsg (int type, const std::string &str_msg, int flag, int id)
{
	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (SAMSON_OBJMGR::instance()->RunID());
	sh->peer_id (SAMSON_OBJMGR::instance()->ModelID());
	sh->message_id (id);
	sh->app_msg_id (0);
	sh->unit_id (SAMSON_OBJMGR::instance()->UnitID());
	sh->type (type);
	sh->bit_flags(flag);
	sh->frame_count(0);
	sh->send_count(0);
	sh->data_length (str_msg.length());

	return this->publish (str_msg, sh);
}

int
SharedAppMgr::sendMsgOnCID (int cid, const char *msg, unsigned int len)
{
	// allocated a header
	SamsonHeader *sh = new SamsonHeader();
	sh->run_id (SAMSON_OBJMGR::instance()->RunID());
	sh->peer_id (SAMSON_OBJMGR::instance()->ModelID());
	sh->message_id (0);
	sh->app_msg_id (0);
	sh->dest_peer_id(cid);
	sh->unit_id (SAMSON_OBJMGR::instance()->UnitID());
	sh->type (SimMsgType::DATA);
	sh->bit_flags(SimMsgFlag::p2ch);
	sh->frame_count(0);
	sh->send_count(0);
	sh->data_length (len);

	// Allocate a new Message_Block for sending this message
	ACE_Message_Block *data_mb =
		new ACE_Message_Block (
			len,
			ACE_Message_Block::MB_DATA,
			0,
			0,
			0,
			0);

	if (data_mb == 0 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SharedAppMgr::publish() -> Data Messsage_Block Allocation Error\n"), -1);

	// copy the data into the message block  (costly?)  !!! this sets the mb length!!!!!
	if ( data_mb->copy(msg,len) == -1 )
		ACE_ERROR_RETURN ((LM_ERROR, "(%P|%t)  SharedAppMgr::publish() -> Data Copy Error\n"), -1);

	return this->publish(data_mb,sh);
}


}  // namespace

