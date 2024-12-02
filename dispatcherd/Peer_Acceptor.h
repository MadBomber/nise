/**
*    @file Peer_Connector.h
*
*    @author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
*
*    @brief Performs active network connection
*
*/

#ifndef PEER_ACCEPTOR_H
#define PEER_ACCEPTOR_H

#include "ISE.h"

#include "DispatcherConfig.h"

#include <sstream>


#include "ace/Service_Config.h"
#include "ace/Acceptor.h"
#include "ace/SOCK_Acceptor.h"
#include "ace/Recursive_Thread_Mutex.h"

// Boost Serialization
#include <boost/serialization/string.hpp>
#include <boost/serialization/utility.hpp>
#include <boost/serialization/version.hpp>
#include <boost/serialization/serialization.hpp>

#include "ISEExport.h"
#include "ConnectionHandler.h"


namespace Samson_Peer {

// forward declarations
class ConnectionRecord;

// =====================================================================================
class ISE_Export Peer_Acceptor : public ACE_Acceptor<ConnectionHandler, ACE_SOCK_ACCEPTOR>
{
	// = TITLE
	//     A concrete factory class that setups connections to peerds
	//     and produces a new ConnectionHandler object to do the dirty
	//     work...
public:
	Peer_Acceptor () {}
	// void constructor

	virtual ~Peer_Acceptor () {}
	// void destricutor

	Peer_Acceptor (ConnectionRecord *);
	// Constructor.

	virtual int make_svc_handler (ConnectionHandler *&ch);
	// Hook method for creating an appropriate <ConnectionHandler>.

	virtual int accept_svc_handler (ConnectionHandler *ch);
	// Hook method for accepting a connection into the
	// <ConnectionHandler>.

	int open (u_short);
	//  the <Peer_Acceptor>.

	void status (std::stringstream &, bool);

	// Used by boost serialzation to save/restore one of these!
	template<class Archive>// TODO move to C++ stl ??
	void serialize(Archive & ar, const unsigned int /* file_version */)
	{
	  std::string    listen_addr     = listen_addr_.get_host_addr();
	  std::string    connection_addr = connection_addr_.get_host_addr();
	  unsigned short listen_port     = listen_addr_.get_port_number();
	  unsigned short connection_port = connection_addr_.get_port_number();
	  unsigned int   ch_set_size     = sim_entity_->ch_set_.size();
	  using boost::serialization::make_nvp;
		ar
		& make_nvp("sim_entity_id"   , sim_entity_->id_)
		& make_nvp("listen_addr"     , listen_addr)
		& make_nvp("listen_port"     , listen_port)
		& make_nvp("connection_addr" , connection_addr)
		& make_nvp("connection_port" , connection_port)
		& make_nvp("proxy_role"      , sim_entity_->proxy_role_)
		& make_nvp("num_ch"          , ch_set_size)
		& make_nvp("bound_2_handler" , bound_2_handler)
		;
	}

protected:
	typedef ACE_Acceptor<ConnectionHandler, ACE_SOCK_ACCEPTOR> inherited;
	// Make life easier later on.

	ACE_INET_Addr listen_addr_;
	// Our acceptor addr.

	ACE_INET_Addr connection_addr_;
	// Our connection addr.

	ConnectionRecord *sim_entity_;
	// There is a one-to-one mapping to ConnectionRecord
	
	ACE_Recursive_Thread_Mutex mutex_;

public:
	bool bound_2_handler;
};

}

#endif /* PEER_ACCEPTOR_H */
