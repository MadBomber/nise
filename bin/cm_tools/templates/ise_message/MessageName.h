/**
 *	@file <%= message_name.to_camelcase %>.h
 *
 *	@author <%= ENV['USER'] %>
 *
 * TODO: This IseMessage is specific for an XML-only message; need example fo a binary message
 */


#ifndef _<%= message_name.upcase %>_H
#define _<%= message_name.upcase %>_H

#include <string>

#include "ISEExport.h"
#include "XmlObjMessage.h"

// Additional includes as necessary
// Example: #include "Coord.h"


struct ISE_Export <%= message_name.to_camelcase %> : public XmlObjMessage<<%= message_name.to_camelcase %>>
{
	<%= message_name.to_camelcase %> (void) : XmlObjMessage<<%= message_name.to_camelcase %>>(std::string("<%= message_name.to_camelcase %>"), std::string("<%= message_desc %>")) {}

// Define the messages items like this:
//	#define ITEMS \
	ITEM(std::string,	traj_file_) \
	ITEM(double,		lat_origin_degrees_) \
	ITEM(double,		lon_origin_degrees_) \
	ITEM(unsigned int,	launch_frame_) \
	ITEM(double,		heading_degrees_)
	#include "messages.inc"

};

#endif
