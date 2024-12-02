/**
 *	@file DispatcherIdentity.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#include "DispatcherIdentity.h"
#include "Options.h"
#include "auto.h"


#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include <boost/shared_ptr.hpp>

#include "ace/Message_Block.h"

namespace Samson_Peer {


//............................................................................
DispatcherIdentity::DispatcherIdentity() : state_(Active)
{
	ACE_TRACE("DispatcherIdentity::DispatcherIdentity");
}

// ==========================================================================
DispatcherIdentity::~DispatcherIdentity()
{
	ACE_TRACE("DispatcherIdentity::~DispatcherIdentity");
	if ( state_ != Destroyed ) this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~DispatcherIdentity called.\n"));
#endif
}

// ==========================================================================
void DispatcherIdentity::destroy (void)
{
	ACE_TRACE("DispatcherIdentity::destroy");
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) DispatcherIdentity destoyed.\n"));
#endif
	this->map_.clear();
	this->state_ = Destroyed;
}

// ==========================================================================
void
DispatcherIdentityRecord::print(std::stringstream &my_report) const
{
	my_report
		<< std::setw(5) << this->chid << " "
		<< std::setw(5) << this->peer << " "
		<< std::setw(5) << this->node << " "
		<< std::hex << this->ch << std::dec
		<< std::endl;
}

// =====================================================================
//  there is only one modelid in the table
bool
DispatcherIdentity::findPeerID (ACE_UINT32 id, DispatcherIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<D_PID>().find(id));
	if(ptr != this->map_.get<D_PID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
//  there is only one modelid in the table, get the connection handler
ConnectionHandler *
DispatcherIdentity::getCHfromPeerID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<D_PID>().find(id));
	if(ptr != this->map_.get<D_PID>().end())
	{
		result = ptr->ch;
	}
	return result;
}

/// =====================================================================
//  there is only one modelid in the table, get the connection handler
ConnectionHandler *
DispatcherIdentity::getCHfromNodeID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<D_NID>().find(id));
	if(ptr != this->map_.get<D_NID>().end())
	{
		result = ptr->ch;
	}
	return result;
}

/// =====================================================================
//  there is only one CHID in the table, get the connection handler
ConnectionHandler *
DispatcherIdentity::getCHfromCHID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<D_CHID>().find(id));
	if(ptr != this->map_.get<D_CHID>().end())
	{
		result = ptr->ch;
	}
	return result;
}

// =====================================================================
// Reevaluate this one
bool
DispatcherIdentity::findNodeID (ACE_UINT32 id, DispatcherIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<D_NID>().find(id));
	if(ptr != this->map_.get<D_NID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

/// =====================================================================
// Reevaluate this one
bool
DispatcherIdentity::findCHID (ACE_INT32 id, DispatcherIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<D_CHID>().find(id));
	if(ptr != this->map_.get<D_CHID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
const std::string
DispatcherIdentity::report()
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	if ( !this->map_.empty () )
	{
		*my_report
			<< " CHID Peer  Node  ConnHndlr" << std::endl
			<< "----- ----- ----- ---------" << std::endl;


		for( AUTO(it,this->map_.get<D_CHID>().begin()); it != this->map_.get<D_CHID>().end(); it++)
		{
			it->print(*my_report);
		}
	}

	return my_report->str();
}

// =====================================================================
const std::string
DispatcherIdentity::report_xml(void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/dispatchers.xsl");
		for( AUTO(it,this->map_.get<D_CHID>().begin()); it != this->map_.get<D_CHID>().end(); it++)
		{
			oa & boost::serialization::make_nvp("dispatcher",*it);
		}
	}
	return my_report.str();
}

} // namespace
