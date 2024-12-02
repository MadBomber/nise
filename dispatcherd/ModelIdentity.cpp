/**
 *	@file SamsonIdentity.cpp
 *
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#include <iostream>
#include <string>
#include <iomanip>
#include <fstream>
#include <sstream>

#include <boost/shared_ptr.hpp>

#include "ace/Message_Block.h"

#include "ModelIdentity.h"
#include "Options.h"
#include "auto.h"

namespace Samson_Peer {

// ==========================================================================
ModelIdentity::ModelIdentity() : state_(Active)
{
	ACE_TRACE("ModelIdentity::ModelIdentity");
}

// ==========================================================================
ModelIdentity::~ModelIdentity()
{
	ACE_TRACE("ModelIdentity::~ModelIdentity");
	if ( state_ != Destroyed ) this->destroy();
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ~ModelIdentity called.\n"));
#endif
}

// ==========================================================================
void ModelIdentity::destroy (void)
{
#if 1
	ACE_DEBUG ((LM_DEBUG, "(%P|%t) ModelIdentity destoyed.\n"));
#endif
	this->map_.clear();
	this->state_ = Destroyed;
}

// ==========================================================================
void
ModelIdentityRecord::print(std::stringstream &my_report) const
{
	// "%5d %5d %5d %5d %12s %3d %5d %8d %0.8x \n",
	my_report
		<< std::setw(5) << this->chid << " "
		<< std::setw(5) << this->jid << " "
		<< std::setw(5) << this->mid << " "
		<< std::setw(3) << this->unitid << " "
		<< std::setw(5) << this->statsid << " "
		<< std::setw(5) << this->nodeid << " "
		<< std::setw(8) << this->pid << " "
		<< std::hex << this->ch << std::dec << " "
		<< std::setw(12) << this->mid_name
		<< std::endl;
}

// =====================================================================
//  there is only one modelid in the table
bool
ModelIdentity::findModelID (ACE_UINT32 id, ModelIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<M_MID>().find(id));
	if(ptr != this->map_.get<M_MID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
//  there is only one modelid in the table, get the connection handler
ConnectionHandler *
ModelIdentity::getCHfromModelID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<M_MID>().find(id));
	if(ptr != this->map_.get<M_MID>().end())
	{
		result = ptr->ch;
	}
	return result;
}

// =====================================================================
//  there is only one modelid in the table
void
ModelIdentity::unbindModelID (ACE_UINT32 id)
{
	ModelIdentityRecord dummy;
	if (findModelID(id,&dummy))
		this->map_.get<M_MID>().erase(id);
	else
	{
		ACE_DEBUG((LM_ERROR, "(%P|%t) ModelIdentidy:unbindModelID failed for %d\n", id));
		ACE_DEBUG((LM_DEBUG, "%s", this->report().c_str()));
	}

}


// =====================================================================
//  there is only one modelid in the table, get the connection handler
ConnectionHandler *
ModelIdentity::getCHfromCHID (ACE_UINT32 id)
{
	ConnectionHandler *result = 0;
	AUTO(ptr,this->map_.get<M_CHID>().find(id));
	if(ptr != this->map_.get<M_CHID>().end())
	{
		result = ptr->ch;
	}
	return result;
}

// =====================================================================
// Reevaluate this one
bool
ModelIdentity::findNodeID (ACE_UINT32 id, ModelIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<M_NID>().find(id));
	if(ptr != this->map_.get<M_NID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
// Reevaluate this one
bool
ModelIdentity::findCHID (ACE_INT32 id, ModelIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<M_CHID>().find(id));
	if(ptr != this->map_.get<M_CHID>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
void
ModelIdentity::unbindCHID(int chid)
{
	ModelIdentityRecord dummy;
	if (findCHID(chid,&dummy))
		this->map_.get<M_CHID>().erase(chid);
	else
	{
		ACE_DEBUG((LM_ERROR, "(%P|%t) ModelIdentidy:unbindCHID failed for %d\n", chid));
		ACE_DEBUG((LM_DEBUG, "%s", this->report().c_str()));
	}
}

// =====================================================================
// Reevaluate this one
bool
ModelIdentity::findCH (ConnectionHandler *ch, ModelIdentityRecord *entity)
{
	bool result = false;
	AUTO(ptr,this->map_.get<M_CON>().find(ch));
	if(ptr != this->map_.get<M_CON>().end())
	{
		*entity = *ptr;
		result = true;
	}
	return result;
}

// =====================================================================
void
ModelIdentity::unbindCH(ConnectionHandler *ch)
{
	ModelIdentityRecord dummy;
	if (findCH(ch,&dummy))
		this->map_.get<M_CON>().erase(ch);
	else
	{
		ACE_DEBUG((LM_ERROR, "(%P|%t) ModelIdentidy:unbindCH failed for %x\n", ch));
		ACE_DEBUG((LM_DEBUG, "%s", this->report().c_str()));
	}
}

// =====================================================================
const std::string
ModelIdentity::report(void)
{
  std::stringstream my_report;

  if ( !this->map_.empty () ) {
    my_report
      << " CHID  JID   MID  UID  SID  Peer    PID    ConnHndlr  Model Name  (" <<  this->map_.size() << ")" << std::endl
      << "----- ----- ----- --- ----- ----- -------- --------- ------------" << std::endl;

	for( AUTO(it,this->map_.get<M_CHID>().begin()); it != this->map_.get<M_CHID>().end(); it++)
		it->print(my_report);
  }
  return my_report.str().c_str();
}

// =====================================================================
const std::string
ModelIdentity::report_xml(void)
{
	std::stringstream my_report;
	{
		boost::archive::my_xml_oarchive oa(my_report,"/models.xsl");
		using boost::serialization::make_nvp;
		for( AUTO(it,this->map_.get<M_CHID>().begin()); it != this->map_.get<M_CHID>().end(); it++)
		{
			oa & make_nvp("model",*it);
		}
	}
	return my_report.str();
}



} // namespace
