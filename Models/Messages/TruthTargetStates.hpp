#ifndef _TRUTHTARGETSTATES_HPP
#define _TRUTHTARGETSTATES_HPP

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "ISEExport.h"
#include "XmlObjMessage.h"

//.................................................................................
class ISE_Export TruthTargetStates :  public XmlObjMessage<TruthTargetStates>
{
	public:
		TruthTargetStates (void) : 
			XmlObjMessage<TruthTargetStates>(std::string("TruthTargetStates"), std::string("Target Truth")) {}
		

	#define ITEMS \
	ITEM(double, time_) \
	ITEM(SamsonMath::Vec3<double>, position_) \
	ITEM(SamsonMath::EulerAngles,  attitude_) \
	ITEM(ACE_UINT32,               unitID_)
	#include "messages.inc"

};

#endif
