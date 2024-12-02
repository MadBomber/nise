#ifndef _LLA_POSITION_HPP
#define _LLA_POSITION_HPP

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "ISEExport.h"
#include "XmlObjMessage.h"

//.................................................................................
class ISE_Export LLA_Vehicle_State :  public XmlObjMessage<LLA_Vehicle_State>
{
	public:
		LLA_Vehicle_State (void) :
			XmlObjMessage<LLA_Vehicle_State>(std::string("LLA_Vehicle_State"), std::string("LLA Vehicle Position State - decimal radians for lat/lon and decimal meters for alt")) {}


	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, lla_) \
	ITEM(SamsonMath::Vec3<double>,  velocity_) \
	ITEM(SamsonMath::EulerAngles,  attitude_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"

};

#endif
