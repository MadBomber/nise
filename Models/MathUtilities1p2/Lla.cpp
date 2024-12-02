////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Lla.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Lla.
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

#include "Lla.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:    Lla
// Description:  Basic constructor for Lla.
// Inputs:       aRhs
// Output:       none
////////////////////////////////////////////////////////////////////////////////

Lla::Lla (const Vec3<double> & aRhs)
{
   setLatitude  (aRhs.getX ());
   setLongitude (aRhs.getY ());
   setAltitude  (aRhs.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:    Lla
// Description:  This is setting setLatitude and others to initial conditions
//               of aLatitude and others
// Inputs:       aLatitude
//               aLongitude
//               aAltitude
// Output:       none
////////////////////////////////////////////////////////////////////////////////

Lla::Lla (const double aLatitude, const double aLongitude, const double aAltitude)
{
   setLatitude  (aLatitude);
   setLongitude (aLongitude);
   setAltitude  (aAltitude);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ~Lla
// Description:  Basic destructor for Lla.
////////////////////////////////////////////////////////////////////////////////

Lla::~Lla (void)
{
}

}; // namespace
