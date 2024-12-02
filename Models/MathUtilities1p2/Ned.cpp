////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Ned.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Ned.
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

#include "Ned.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:    Ned
// Description:  Basic constructor for Ned.
// Inputs:       aRhs
// Output:       none
////////////////////////////////////////////////////////////////////////////////

Ned::Ned (const Vec3<double> & aRhs)
{
   setNorth (aRhs.getX ());
   setEast  (aRhs.getY ());
   setDown  (aRhs.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:    Ned
// Description:  This is setting setLatitude and others to initial conditions of
//               aNorth and others
// Inputs:       aNorth
//               aEast
//               aDown
// Output:       none
////////////////////////////////////////////////////////////////////////////////

Ned::Ned (double aNorth, double aEast, double aDown)
{
   setNorth (aNorth);
   setEast  (aEast);
   setDown  (aDown);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ~Ned
// Description:  Basic destructor for Ned.
////////////////////////////////////////////////////////////////////////////////

Ned::~Ned (void)
{
}

}; // namespace
