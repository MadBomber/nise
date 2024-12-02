/**
 *	@file ConnectionTable.cpp
 *
 * 	@brief Records Active Connections
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "ConnectionTable.h"
#include "Peer_Acceptor.h"
#include "EventChannel.h"
#include "Options.h"
#include "XMLParser.h"
#include "TransmitHandler.h"
#include "ReceiveHandler.h"
#include "TransceiverHandler.h"
#include "DebugFlag.h"
#include "auto.h"
#include "LogLocker.h"

// std includes
#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>

//....boost serialization
#include <boost/spirit/include/classic_spirit.hpp>
using namespace boost::spirit::classic;

#include <boost/archive/tmpdir.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/map.hpp>
#include "my_xml_oarchive.h"


//....boost lambda
#include <boost/lambda/lambda.hpp>
#include <boost/lambda/bind.hpp>

namespace Samson_Peer
{

#define KEY_HIGH 65535
ACE_INT32 ConnectionTable::FreeKey= KEY_HIGH;

// =====================================================================
ConnectionTable::~ConnectionTable()
{
	ACE_TRACE("ConnectionTable::~ConnectionTable()");

	if (this->state_ != ConnectionTable::Empty) this->destroy();

#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~ConnectionTable called.\n"));
#endif
}

// =====================================================================
int ConnectionTable::initialize()
{
	ACE_TRACE("ConnectionTable::initialize");

	this->state_ = ConnectionTable::Empty;

	*mySpiritParseRulePtr = confix_p("<ConnectionRecord>", (*anychar_p)[&Samson_Peer::ConnectionTable::restore],
			"</ConnectionRecord>");
	XML_PARSER::instance()->register_parser(mySpiritParseRulePtr);

	return 1;
}

// =====================================================================
void ConnectionTable::destroy()
{
	//int silly=1;

	ACE_TRACE("ConnectionTable::destroy");

	this->state_ = ConnectionTable::Clearing;

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	for (it= this->map_.begin() ; it != this->map_.end(); it++)
	{
		//ACE_INT32 cid = it->first;
		ConnectionRecord *entity = it->second;

		//---------------------------------------------------------------------------------------------------------
		if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) ConnectionTable::destroy(%d) Type(%c) Size(%d)\n",
				entity->id_, entity->connection_type_, entity->ch_set_.size()
			));
		}


		if (entity->connection_type_ == 'P' && entity->ch_set_.empty() )
		{
			// This is a listener that was never connected to
			entity->peer_acceptor_->close();
		}
		else if ( !entity->ch_set_.empty() )
		{

			//while (DebugFlag::instance ()->DebugWait) ;
			//while (silly) ;

			//---------------------------------------------------------------------------------------------------------
			if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
			{
				LogLocker log_lock;

				ACE_DEBUG((LM_DEBUG,
						"(%P|%t) ConnectionTable::destroy -> number of ch's alive %d  type %c\n",
						entity->ch_set_.size(), entity->proxy_role_
					));
			}

			// I think this is causing the dispatcher to core dump
			if ( entity->proxy_role_ == 'C')  continue;

			// A connection may/may not exist, but it existed once.
			std::set<ConnectionHandler *>::iterator it = entity->ch_set_.begin();
			while (it != entity->ch_set_.end())
			{
				ConnectionHandler *ch = (*it);


				//---------------------------------------------------------------------------------------------------------
				if (DebugFlag::instance ()->enabled (DebugFlag::NET_DEBUG))
				{
					LogLocker log_lock;

					ACE_DEBUG((LM_DEBUG,
							"(%P|%t) ConnectionTable::destroy -> processing(%d|0x%x|%d)\n",
							ch->get_handle(), ch, ch->connection_id()
						));
				}

				// If we did not have this statement, we would abort when exiting
				// with some end-points not connected.
				if (ch->state()==ConnectionHandler::CONNECTING)
					EVENT_CHANNEL_MGR::instance ()->cancel_connection(ch);
				else
				{
					ch->state(ConnectionHandler::DISCONNECTING);
				}

				it++; // go to the next one

				// keep the connection handler from being called prior to destruction
				ACE_Reactor_Mask mask =
						ACE_Event_Handler::DONT_CALL | ACE_Event_Handler::ALL_EVENTS_MASK;
				ACE_Reactor::instance ()->remove_handler (ch, mask);

				ch->destroy();  // triggers destructor which will remove itself from the handler set

			}

			//now clean out the ConnectionHandler set
			//entity->ch_set_.clear();

			if (entity->peer_acceptor_)
			{
				// It was an allocated acceptor...release the memory
				// ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~Peer_Acceptor %0x\n",entity->peer_acceptor_));
				delete entity->peer_acceptor_;
			}
		}

		//  We are finished with this element
		// ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~entity %0x\n",entity));
		delete entity;
	}

	// remove the mapping
	this->map_.clear();

	// remove the parser rule
	// delete this->mySpiritParseRulePtr;

	this->state_ = ConnectionTable::Empty;
}

// =====================================================================
// =====================================================================
//	This section of code is used build the ConnectionTable
// =====================================================================
// =====================================================================


// ==========================================================================
ConnectionRecord * ConnectionTable::find(ACE_INT32 id)
{
	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	return ((it=this->map_.find(id))!=this->map_.end()) ? it->second : 0;
}

// ==========================================================================
int ConnectionTable::bind(ConnectionRecord *entity)
{
	// TODO Rethink the State logic...new scheme of populating is harder to control.
	this->state_ = ConnectionTable::Populating;

	if (entity->id_ == 0) // need to create an key!!
		entity->id_ = ConnectionTable::FreeKey--;

	if (DebugFlag::instance ()->enabled(DebugFlag::XML_DEBUG) )
	{
		LogLocker log_lock;

		ACE_DEBUG((LM_DEBUG,
				"(%P|%t) ConnectionTable::bind (%0X) with id= %d\n", entity,
				entity->id_));
	}

	std::pair<std::map<ACE_INT32, ConnectionRecord *>::iterator,bool> result =
			this->map_.insert(std::pair<ACE_INT32, ConnectionRecord *>(entity->id_,entity));

	if (result.second==false)
	{
		LogLocker log_lock;

		ACE_ERROR_RETURN ((LM_ERROR,
				"(%P|%t) duplicate connection %d, already bound\n",
				entity->id_),
		-1);
	}

	return 0;
}

// ==========================================================================
int
ConnectionTable::unbind (ACE_INT32 id)
{
	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	if ((it=this->map_.find(id))!=this->map_.end())
	{
		this->map_.erase(it);
		return 0;
	}
	else
	return -1;
}

// =====================================================================
const std::string
ConnectionTable::compute_stats(int type)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	unsigned int count = 0;

	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;

		std::set<ConnectionHandler *>::iterator it;
		for ( it=entity->ch_set_.begin(); it != entity->ch_set_.end(); it++ )
		{
			(*it)->stats( *my_report, ((count==0)?true:false), type);
			count++;
		}
	}

	if (DebugFlag::instance ()->enabled (DebugFlag::XML_DEBUG) )
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG, "(%P|%t) Computed Stats for %d connections\n",count));
	}

	return my_report->str();
}

// ==========================================================================
// Initiate all active connections, listen for passive
// returns 0 for success and -1 for failure

int
ConnectionTable::initiate_connections (void)
{
	if ( this->state_ == ConnectionTable::Populating && this->map_.size() >0)
	{
		this->state_ = ConnectionTable::Populated;

		std::map<ACE_INT32, ConnectionRecord *>::iterator it;
		for ( it= this->map_.begin(); it != this->map_.end(); it++ )
		{
			ConnectionRecord *entity = it->second;
			if ( this->initiate_connection(entity) != 0) return -1;

		} // for each entity loop

}
	else
	{
		LogLocker log_lock;

		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::initiate_connections:  bad call, map size = %d and state = %d\n",
				this->map_.size(), this->state_));
	}

	return 0;
}

// ==========================================================================
// Initiate all active connections, listen for passive
// returns 0 for success and -1 for failure

int
ConnectionTable::initiate_connection (ConnectionRecord *entity)
{
	// if the connection is active then allocate
	if ( entity->connection_type_ == 'A' )
	{
		ConnectionHandler *ch = 0;
		if ( (ch = this->make_connection_handler (entity)) == 0 )
		{
			ACE_DEBUG ((LM_ERROR, "(%P|%t) ConnectionTable...ConnectionHandler Allocation Error %d\n", entity->id_));
			return -1;
		}
		entity->ch_set_.insert(ch);

		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG,
				"(%P|%t) ConnectionTable...Active Connection Prepared  (%d)->(%0x) size %d\n",
				entity->id_, ch, entity->ch_set_.size()
			));
		}

		// This is a crude interim hack, this is an active connection that needs starting
		// It can only really have one and only one ConnectionHandler !!!!
		if ( entity->ch_set_.size() != 1 )
		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::initiate_connections: ch size not one (%d)\n",
				entity->ch_set_.size()
			));
		}

		if (EVENT_CHANNEL_MGR::instance ()->initiate_connection (ch,1) == -1)

		{
			LogLocker log_lock;

			ACE_DEBUG ((LM_ERROR, "(%P|%t) ConnectionTable::initiate_connections: EventChanel->initiate_connection failed, handled elsewhere\n"));
		}
	}
	else if ( entity->connection_type_ == 'P' )
	{
		ACE_NEW_RETURN ( entity->peer_acceptor_, Peer_Acceptor (entity), -1);
		if ( entity->peer_acceptor_->open(0) == -1)

		{
			LogLocker log_lock;
			ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::initiate_connections: PeerAcceptor->open failed, handled elsewhere\n"));
		}
	}
	else
	{
		LogLocker log_lock;
		ACE_ERROR_RETURN ((LM_WARNING, "ConnectionTable...connection neither active or passive (%c)\n", entity->connection_type_ ),-1);
	}
	return 0;
}

// ==========================================================================
// return an array of command connections (sans)

int
ConnectionTable::command_connections (ConnectionHandler **cha)
{
	int i = 0;

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;
		if ( !entity->isMaster_ && entity->proxy_role_ == 'C' )
		{
			std::set<ConnectionHandler *>::iterator it;
			for ( it=entity->ch_set_.begin(); it != entity->ch_set_.end(); it++ )
			{
				*cha++ = (*it);
				i++;
			}
		}
	}
	return i;
}

// ==========================================================================
// return an array of command connections (sans)

int
ConnectionTable::master_connections (ConnectionHandler **cha)
{
	int i = 0;

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;
		if ( !entity->isMaster_ && entity->proxy_role_ == 'M' )
		{
			std::set<ConnectionHandler *>::iterator it;
			for ( it=entity->ch_set_.begin(); it != entity->ch_set_.end(); it++ )
			{
				*cha++ = (*it);
				i++;
			}
		}
	}
	return i;
}



// ==========================================================================
// close active/passive connections

void
ConnectionTable::close_connections (void)
{
	ACE_TRACE("ConnectionTable::close_connections");

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;
		std::set<ConnectionHandler *>::iterator it0 = entity->ch_set_.begin() ;
		while (it0 != entity->ch_set_.end())
		{
			ACE_DEBUG ((LM_DEBUG,"(%P|%t) closing down connection %d\n",(*it0)->connection_id ()));

			// If we dot not have this statement, we will abort when exiting
			// if there was a connection.
			if ((*it0)->state()==ConnectionHandler::CONNECTING)
				EVENT_CHANNEL_MGR::instance ()->cancel_connection (*it0);

			// Mark ConnectionHandler as DISCONNECTING so we don't try to reconnect...
			(*it0)->state (ConnectionHandler::DISCONNECTING);

			// Let the framework disconnect and remove the connection
			(*it0)->destroy();

			// Remove from the set of connections
			entity->ch_set_.erase(*it0++);
		}
	}
}

// =====================================================================
// Create the desired ConnectionHandler  (Factory Method)
// TODO  on refactoring, review this routine placement

ConnectionHandler *
ConnectionTable::make_connection_handler (ACE_INT32 id)
{
	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	if ( (it=this->map_.find(id)) != this->map_.end() )
	{
		return this->make_connection_handler(it->second);
	}
	return 0;
}

// =====================================================================
// Create the desired ConnectionHandler  (Factory Method)
// TODO  on refactoring, review this routine placement

ConnectionHandler *
ConnectionTable::make_connection_handler (ConnectionRecord *entity)
{
	ACE_TRACE("make_connection_handler");

	//ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::make_connection_handle(%0X)\n",entity));

	// the returned ConnectionHandler
	ConnectionHandler *ch = 0;

	//.................................... Transmit ONLY
	if (entity->proxy_role_ == 'T')
	{
		ACE_NEW_RETURN ( ch, TransmitHandler (entity), 0);
	}

	//..................................... Receive ONLY

	else if (entity->proxy_role_ == 'R')
	{
		ACE_NEW_RETURN ( ch, ReceiveHandler (entity), 0);
	}

	//......................................  Bi-Directional

	else
	{
		ACE_NEW_RETURN ( ch, TransceiverHandler (entity), 0);
	}

	return ch;
}

// ====================================================================
// Insert ConnectionHandler in proper connection_set
// TODO:  This feels wrong, there must be a better way

void
ConnectionTable::insert_connection_handler(ACE_INT32 id, ConnectionHandler *ch)
{
	std::map<ACE_INT32, ConnectionRecord *>::iterator it = this->map_.find(id);
	if ( it != this->map_.end() )
	{
			it->second->ch_set_.insert(ch);

	}
	return;
}

// =====================================================================
// =====================================================================
//  This section us used to interface with the Boost Serialization
// =====================================================================
// =====================================================================

void
ConnectionTable::restore(const char *begin, const char *end)
{
	if ( CONNECTION_TABLE::instance ()->state() == ConnectionTable::Populated )
	{
		CONNECTION_TABLE::instance ()->destroy();
	}
	CONNECTION_TABLE::instance ()->state (ConnectionTable::Populating);

	std::string str(begin, end);

	if (DebugFlag::instance ()->enabled (DebugFlag::XML_DEBUG) )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::restore (static) -> \n----\n%s\n---\n",str.c_str()));
	}

	// Allocate a ConnectionRecord  (dangling pointer managed by the table)
	ConnectionRecord *entry = new ConnectionRecord();
	// TODO....catch null allocation

	if (DebugFlag::instance ()->enabled (DebugFlag::XML_DEBUG) )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::restore (static) -> Entity Allocates at %0X\n",entry));
	}

	// open the XML boost serialization archive and restore
	std::stringstream ifs(str);
	assert(ifs.good());
	boost::archive::xml_iarchive ia(ifs,1);
	ia >> BOOST_SERIALIZATION_NVP(*entry);

	// Set Defaults
	entry->priority_ = 0;
	entry->isMaster_ = false;
	entry->tcp_nodelay = false;
	entry->first_message_alert_ = false;

	// Override the zero values
	entry->max_retry_timeout_ = (entry->max_retry_timeout_ == 0) ? Options::instance ()->max_timeout () : entry->max_retry_timeout_;
	entry->send_buff = (entry->send_buff == 0) ? Options::instance ()->max_buffer_size () : entry->send_buff;
	entry->recv_buff = (entry->recv_buff == 0) ? Options::instance ()->max_buffer_size () : entry->recv_buff;
	entry->read_buff = (entry->read_buff == 0) ? Options::instance ()->max_buffer_size () : entry->read_buff;

	// Default the Acceptor Pointers
	entry->peer_acceptor_ = 0;

	// Bind this so it can be known as a  "possible entity" for routing.
	if ( CONNECTION_TABLE::instance ()->bind (entry) != 0 )
	{
		LogLocker log_lock;
		ACE_DEBUG ((LM_DEBUG, "(%P|%t) ConnectionTable::restore (static) -> bind failed on %d\n",entry->id_));
	}
}

// =============================================================================================================
template<typename FIELD> class Filter
{

public:
	Filter(FIELD ConnectionRecord::*mem,
			std::map<ACE_INT32, ConnectionRecord *>& map,
			boost::archive::my_xml_oarchive& oa) :
		mem(mem), map(map), oa(oa)
	{
	}
	//FilterId(unsigned int ConnectionRecord::*mem, std::map<ACE_INT32, ConnectionRecord *>& map, boost::archive::my_xml_oarchive& oa):mem(mem),map(map),oa(oa){}
	void operator()(unsigned int val) const
	{
		for (AUTO(it,map.begin()); it!=map.end(); ++it)
		{
			if (it->second->*mem == val)
			{
				oa & boost::serialization::make_nvp("entity", *it->second) ;
				break;
			}
		}
	}
	template<class IT> void operator()(IT b, IT e) const
	{
		std::string val(b, e);
		for (size_t i=val.find("%20"); i!=std::string::npos; i=val.find("%20"))
			val.replace(i, 3, " ");

		for (AUTO(it,map.begin()); it!=map.end(); ++it)
		{
			if (it->second->*mem == val)
			{
				oa & boost::serialization::make_nvp("entity", *it->second) ;
				//break;
			}
		}
	}
private:
	FIELD ConnectionRecord::*mem;
	std::map<ACE_INT32, ConnectionRecord *>& map;
	boost::archive::my_xml_oarchive& oa;
};
















// =====================================================================
// Print the Connection Table
const std::string
ConnectionTable::print_ctable_xml (void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/ctable.xsl");
		for (std::map<ACE_INT32, ConnectionRecord *>::iterator it= this->map_.begin(); it != this->map_.end(); it++ )
		{
			oa & boost::serialization::make_nvp("entity",*it->second);
		}
	}

	//ACE_DEBUG((LM_DEBUG,"(%P|%t) ConnectionTable::print_ctable_xml -> \n%s\n",my_report.str().c_str()));

	return my_report.str();
}



// =====================================================================
// Print the Connection Table
const std::string
ConnectionTable::print_ctable()
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	*my_report
	<< "Connection Table (" << this->map_.size() << ")" << std::endl;

	if (Options::instance ()->enabled(Options::DATABASE_INIT))
	{
		*my_report
		<< "Key (" << Options::instance ()->initialization_key ()->c_str() << ")" << std::endl;
	}

	*my_report
	<< " ID      Name           Header        Address          C D T/O Pr #CH M" << std::endl
	<< "----- --------------- ---------- --------------------- - - --- -- --- -" << std::endl;

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;

		*my_report
		<< std::setw(5) << entity->id_ << " "
		<< std::setw(15) << entity->name_ << " "
		<< std::setw(10) << entity->header_ << " "
		<< std::setw(15) << entity->host_ << ":"
		<< std::setw(5) << entity->port_ << " "
		<< std::setw(1) << entity->connection_type_ << " "
		<< std::setw(1) << entity->proxy_role_ << " "
		<< std::setw(3) << entity->max_retry_timeout_ << " "
		<< std::setw(2) << entity->priority_ << " "
		<< std::setw(3) << entity->ch_set_.size() << " "
		<< std::setw(1) << entity->isMaster_ << " "
		<< std::hex << entity << std::dec << " "
		<< std::endl;
	}
	return my_report->str();
}

// ==========================================================================
// status passive listeners

const std::string
ConnectionTable::status_acceptors (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	int i = 0;

	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		Peer_Acceptor *acceptor = it->second->peer_acceptor_;
		if ( acceptor )
		{
			acceptor->status (*my_report, (i++==0)?true:false);
		}
	}
	return my_report->str();
}

const std::string
ConnectionTable::status_acceptors_xml (void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/acceptors.xsl");
		for(AUTO(it,map_.begin()); it!=map_.end(); ++it)
		{
			Peer_Acceptor *acceptor = it->second->peer_acceptor_;
			if ( acceptor )
			{
				oa & boost::serialization::make_nvp("acceptor",*it->second->peer_acceptor_);
			}
		}
	}
	return my_report.str();
}

// ==========================================================================
// status active connections  (ConnectionHandlers)

const std::string
ConnectionTable::status_connections (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	int i = 0;

	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;
		std::set<ConnectionHandler *>::iterator it;
		for ( it=entity->ch_set_.begin(); it != entity->ch_set_.end(); it++ )
		{
			(*it)->status (*my_report, (i++==0)?true:false);
		}
	}
	return my_report->str();
}

// ==========================================================================
const std::string
ConnectionTable::status_connections_xml (void)
{
	std::stringstream my_report;
	{ // this is scoped to force the my_xml_oarchive dtor
		boost::archive::my_xml_oarchive oa(my_report,"/connections.xsl");
		for(AUTO(it,this->map_.begin()); it!=this->map_.end(); ++it)
		{
			AUTO(&chset,it->second->ch_set_);
			for(AUTO(ih,chset.begin()); ih!=chset.end(); ++ih) oa & boost::serialization::make_nvp("connection",**ih);
		}
	}
	return my_report.str();
}

// ==========================================================================
// status active read connections (ReceiveHandler

const std::string
ConnectionTable::status_recv_connections (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	std::map<ACE_INT32, ConnectionRecord *>::iterator it;
	int i = 0;

	for ( it= this->map_.begin(); it != this->map_.end(); it++ )
	{
		ConnectionRecord *entity = it->second;
		std::set<ConnectionHandler *>::iterator it;
		for ( it=entity->ch_set_.begin(); it != entity->ch_set_.end(); it++ )
		{
			ReceiveHandler *rh = dynamic_cast<ReceiveHandler*>(*it);
			if (rh != 0 )  rh->status (*my_report, (i++==0)?true:false);
		}
	}
	return my_report->str();
}

const std::string
ConnectionTable::status_recv_connections_xml (void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/rcv_connections.xsl");
		for(AUTO(it,this->map_.begin()); it!=this->map_.end(); ++it)
		{
			AUTO(&chset,it->second->ch_set_);
			for(AUTO(ih,chset.begin()); ih!=chset.end(); ++ih)
			{
				ReceiveHandler *rh = dynamic_cast<ReceiveHandler*>(*ih);
				if (rh != 0 ) oa & boost::serialization::make_nvp("rcv_connection", *rh);
			}
		}
	}
	return my_report.str();
}


} // namespace
