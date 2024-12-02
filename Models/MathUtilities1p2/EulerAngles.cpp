////////////////////////////////////////////////////////////////////////////////
//
// Filename:         EulerAngles.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of EulerAngles.
//
// Author:           Hector Bayona
//                   Nancy Anderson
//
// Company Name:     Lockheed Martin
//                   Missiles & Fire Control
//                   Dallas, TX
//
// Revision History:
//
// <yyyymmdd> <Eng> <Desciption of modification>
//  20051114   HLB   Originial Release
//
////////////////////////////////////////////////////////////////////////////////

#define ISE_BUILD_DLL

#include "EulerAngles.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  EulerAngles Constructor
////////////////////////////////////////////////////////////////////////////////

EulerAngles::EulerAngles (const Vec3<double> & aVec)
{
   setX (aVec.getX ());
   setY (aVec.getY ());
   setZ (aVec.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  EulerAngles Constructor
////////////////////////////////////////////////////////////////////////////////

EulerAngles::EulerAngles (const double aRoll, const double aPitch, const double aYaw)
{
   setX (aRoll);
   setY (aPitch);
   setZ (aYaw);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ~EulerAngles Destructor
////////////////////////////////////////////////////////////////////////////////

EulerAngles::~EulerAngles (void)
{
}


//...................................................................................................
ISE_Export ostream& operator<<(ostream& output, const EulerAngles& p) 
{
    output << p.getRoll() << " " << p.getPitch() << " " << p.getYaw();
    return output;
}

}; // namespace
