/**
 *	@file CommandIdentity.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#define ISE_BUILD_DLL

#include "CommandIdentity.h"
#include "Options.h"
#include "auto.h"

#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include <boost/shared_ptr.hpp>

#include "ace/Message_Block.h"

#include "CommandIdentity.h"
#include "Options.h"
#include "auto.h"

namespace Samson_Peer {

// ==========================================================================
// ==========================================================================
// ==========================================================================
CommandIdentity::CommandIdentity() : state_(Active)
{
	ACE_TRACE("CommandIdentity::CommandIdentity");
}


// ==========================================================================
CommandIdentity::~CommandIdentity()
{
	ACE_TRACE("CommandIdentity::~CommandIdentity");
	if ( state_ != Destroyed )  this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~CommandIdentity called.\n"));
#endif
}

// ==========================================================================
void CommandIdentity::destroy (void)
{
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) CommandIdentity destoyed.\n"));
#endif
	this->map_.clear();
	this->state_ = Destroyed;
}

// ==========================================================================
// ==========================================================================
// ==========================================================================
void
CommandIdentityRecord::print(std::stringstream &my_report) const
{
	my_report
		<< std::setw(5) << this->chid << " "
		<< std::hex << this->ch << std::dec
		<< std::endl;
}

// =====================================================================
//  there is only one CHID in the table, get the connection handler
ConnectionHandler *
CommandIdentity::getCHfromCHID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<C_CHID>().find(id));
	if(ptr != this->map_.get<C_CHID>().end())
	{
		result = ptr->ch;
	}
	return result;
}


/// =====================================================================
// Reevaluate this one
bool
CommandIdentity::findCHID (ACE_INT32 id, CommandIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<C_CHID>().find(id));
	if(ptr != this->map_.get<C_CHID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
const std::string
CommandIdentity::report (void)
{
	boost::shared_ptr<std::stringstream> my_report(new std::stringstream);

	if ( !this->map_.empty () )
	{
		*my_report
			<< " CHID ConnHndlr" << std::endl
			<< "----- ---------" << std::endl;


		for( AUTO(it,this->map_.get<C_CHID>().begin()); it != this->map_.get<C_CHID>().end(); it++)
		{
			it->print(*my_report);
		}
	}

	return my_report->str();
}

// =====================================================================
const std::string
CommandIdentity::report_xml (void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/command.xsl");
		for( AUTO(it,this->map_.get<C_CHID>().begin()); it != this->map_.get<C_CHID>().end(); it++)
		{
			oa & boost::serialization::make_nvp("dispatcher",*it);
		}
	}
	return my_report.str();
}

} // namespace
