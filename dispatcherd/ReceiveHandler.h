/**
 *	@file ReceiveHandler.h
 *
 *	@brief Base Class for Dispacter Active Handler
 *
 *	@authoror Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef _RECEIVE_HANDLER_H
#define _RECEIVE_HANDLER_H

#include "ISE.h"

#include "DispatcherConfig.h"
#include "ConnectionHandler.h"
#include "EventHeader.h"

#include <string>
#include <sstream>

namespace Samson_Peer
{

class ISE_Export ReceiveHandler : public virtual ConnectionHandler
{
	// = TITLE
	//     Handles reception of Events from Suppliers.
	//
	// = DESCRIPTION
	//     Performs framing and error checking on Events.  Intended to
	//     run reactively, i.e., in one thread of control using a
	//     Reactor for demuxing and dispatching.
public:
	// = Initialization method.
	ReceiveHandler (ConnectionRecord * const);
	~ReceiveHandler ();

	// = Print status information
	virtual void status (std::stringstream &, bool);

	//static CHFactory<ConnectionHandler,ReceiveHandler> myFactory;

	// Used by boost serialzation to save/restore one of these!
	template<class Archive>
	void serialize(Archive & ar, const unsigned int /* file_version */) 
	{
	  AUTO(handle,get_handle());
	  std::string local_addr(local_addr_.get_host_addr());
	  std::string remote_addr(remote_addr_.get_host_addr());
	  unsigned short local_port(local_addr_.get_port_number());
	  unsigned short remote_port(remote_addr_.get_port_number());

	  std::ostringstream os;
	  os<<std::hex<<data_frag_;
	  std::string data_str(os.str());
	  os<<std::hex<<header_frag_;
	  std::string header_str(os.str());

	  
	  using boost::serialization::make_nvp;
		ar
		& make_nvp("connection_id"   , connection_id_)
		& make_nvp("handle"          , handle)
		& make_nvp("local_address"   , local_addr)
		& make_nvp("local_port"      , local_port)
		& make_nvp("remote_address"  , remote_addr)
		& make_nvp("remote_port"     , remote_port)		
		& make_nvp("data_buf"        , header_str)
		& make_nvp("hdr_buf"         , data_str)
		& make_nvp("hdr_bytes_recvd" , header_recvd_)
		;
	}

	
	
protected:
	// = All the following methods are upcalls, so they can be protected.

	virtual int handle_input (ACE_HANDLE = ACE_INVALID_HANDLE);
	// Receive and process peer events.

	// -------------------------------------------------
	int (ReceiveHandler::*recv_action)(ACE_Message_Block *&, EventHeader *&);
	// points to one of the actions below

	int recv_header (ACE_Message_Block *&, EventHeader *&);
	// Receive an event from a Transmitter.

	int recv_noheader (ACE_Message_Block *&, EventHeader *&);
	// Receive an event from a Transmitter where there is no header.
	// -------------------------------------------------

	// Used in receive_header method
	ACE_Message_Block *data_frag_;
	EventHeader *header_frag_;
	int header_recvd_;
};

} // namespace

#endif // _RECEIVE_HANDLER_H
