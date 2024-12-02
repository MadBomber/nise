/**
 *	@file ConnectionHandlerFactory.h
 * 
 *  @brief Factory to create connections
 * 
 *	@author Jack K. Lavender, Jr. <jack.lavender@lmco.com>
 *
 */

#ifndef CH_FACTORY_T_H
#define CH_FACTORY_T_H

#include "ISE.h"
#include "DispatcherConfig.h"

// forward declaration
class ConnectionRecord;

template <class BT>
class CHFactoryPlant
{
   public:
      CHFactoryPlant() {}
      virtual ~CHFactoryPlant() {}
      virtual BT *createInstance(const ConnectionRecord *) = 0;
};

template <class BT, class ST>
class CHFactory : public CHFactoryPlant<BT>
{
   public:
      CHFactory() {}
      virtual ~CHFactory() {}
      virtual BT *createInstance(const ConnectionRecord *arg) {return new ST(arg);}
};

#endif // FACTORY_T_H

