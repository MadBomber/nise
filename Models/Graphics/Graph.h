////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Graphic.hpp
//
// Company Name:     Lockheed Martin
//                   Missiles & Fire Control
//                   Dallas, TX
//
// Revision History:
//
// <yyyymmdd> <Eng> <Description of modification>
//
////////////////////////////////////////////////////////////////////////////////

#ifndef _GRAPHIC_HPP
#define _GRAPHIC_HPP

#include "ISEExport.h"
#include "SamsonModel.h"

#include "Vec3.hpp"
#include "EulerAngles.hpp"

#include "TruthTargetStates.hpp"
#include "MissileDownlink.hpp"


namespace Samson_Peer { class MessageBase; }

//................................................................
class ISE_Export Graphic : public Samson_Peer::SamsonModel
{
public:
  Graphic():SamsonModel() {}
  ~Graphic() {}
  
  virtual int init(int argc, ACE_TCHAR *argv[]);
  virtual int fini(void);
  
  virtual int MonteCarlo_InitCase (Samson_Peer::MessageBase *) { return 1; }
  virtual int MonteCarlo_Step (Samson_Peer::MessageBase *) { toDB("Graphic"); return 1; }
  virtual int MonteCarlo_EndCase (Samson_Peer::MessageBase *) { return 1; }
  virtual int MonteCarlo_EndRun (Samson_Peer::MessageBase *) { return 1; }
   
  int processTargetInput (Samson_Peer::MessageBase *mb);

private:

  FILE *read_from, *write_to;
  FILE *read_from2, *write_to2;
  
  MyMissileDownlink  *mDownlink;
//  MyMissileDownlink  aDownlink;
//  ObjMessageTempl<MyMissileDownlink> *mDownlink;

  TruthTargetStates *mTgtTruth;

  #define ITEMS \
  ITEM(SamsonMath::Vec3<double>, position)
   #include "model_states.inc"
};

ACE_FACTORY_DEFINE(ISE,Graphic)

#endif

