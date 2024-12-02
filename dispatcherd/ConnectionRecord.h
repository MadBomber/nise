/**
 *	@file ConnectionRecord.h
 *
 *  @class  ConnectionRecord
 *
 *  @brief Structure about an active connection
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef CONNECTION_RECORD_H
#define CONNECTION_RECORD_H

#include "ISE.h"

// STL Set
#include <set>

// Boost Serialization
#include <boost/serialization/string.hpp>
#include <boost/serialization/utility.hpp>
#include <boost/serialization/version.hpp>
#include <boost/serialization/serialization.hpp>


namespace Samson_Peer {

// forward references
class ConnectionHandler;
class Peer_Acceptor;


// ==========================================================================
class ConnectionRecord
	// = TITLE
	//     Stores a connection configuration
{
  public:
	//------------- First the data that is read in ---------------------

	unsigned int id_;
	// Connection id (CID) for this ConnectionHandler.  Used as the Primary Key.

	std::string name_;
	// Connection Name for printing only!

	std::string host_;
	// Host to connect with or to listen on.  This can be a FQDN or IP Address.

	std::string input_filter_;
	// input filter dll name.

	std::string output_filter_;
	// output filter dll name.

	unsigned short port_;
	// Port to connect with or to listen on.

	std::string header_;
	// Header type to transmit/receive.

	char proxy_role_;
	// Direction:
	//  'R' (Receive)
	//  'T' (Transmit)
	//  'C' (Command) ---  Transmit and Receive, Passive ... Automatically opened!
	//  'M' (Master) ---  Transmit and Receive, Link in with Command Channel
	//  'B' (Transmit and Receive)
	//  'E' (Echo)

	char connection_type_;
	// Connection Initiation Roles
	//  'A' (Active) --- Connector,
	//  'P' (Passive) --- Acceptor, Listener, Bind

	unsigned int max_retry_timeout_;
	// Maximum amount of time to wait for reconnecting.

	unsigned int priority_;
	// Channel Priority by which different connection should be
	// serviced.  (Not working for now)

	bool tcp_nodelay;
	// Turn off the Nagel for this Entity.

	bool isMaster_;
	// This Entity is repsonsible for this Router.

	bool first_message_alert_;
	// Alert the master on receipt of first message.

	unsigned int send_buff;
	// Send buffer size,  0 for default.

	unsigned int recv_buff;
	// Receive buffer size,  0 for default.

	unsigned int read_buff;
	// Maximum amount of data to read in one receive.
	// This is used ONLY for the "no header" case

	// Used by boost serialization to save/restore one of these!
	template<class Archive>// TODO move to C++ stl ??
	void serialize(Archive & ar, const unsigned int /* file_version */)
	{
		ar
		& BOOST_SERIALIZATION_NVP(id_)
		& BOOST_SERIALIZATION_NVP(name_)
		& BOOST_SERIALIZATION_NVP(host_)
		& BOOST_SERIALIZATION_NVP(port_)
		& BOOST_SERIALIZATION_NVP(header_)
		& BOOST_SERIALIZATION_NVP(proxy_role_)
		& BOOST_SERIALIZATION_NVP(connection_type_)
		& BOOST_SERIALIZATION_NVP(max_retry_timeout_)
		& BOOST_SERIALIZATION_NVP(priority_)
		& BOOST_SERIALIZATION_NVP(tcp_nodelay)
		& BOOST_SERIALIZATION_NVP(send_buff)
		& BOOST_SERIALIZATION_NVP(recv_buff)
		& BOOST_SERIALIZATION_NVP(read_buff)
		& BOOST_SERIALIZATION_NVP(input_filter_)
		& BOOST_SERIALIZATION_NVP(output_filter_)
		;
	}

	//--------- Now for the dispatcher runtime specific stuff

	Peer_Acceptor *peer_acceptor_;
	// There is a one-to-one mapping with the Peer_Acceptor.
	// only used for a connector!!!!

	mutable std::set<ConnectionHandler *> ch_set_;
	// ConnectionHandler's assigned to this CID
};

} // namespace

#endif  // CONNECTION_RECORD_H

