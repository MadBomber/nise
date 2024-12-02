////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Ecef.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Ecef.
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

#include "Ecef.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Ecef Constructor
////////////////////////////////////////////////////////////////////////////////

Ecef::Ecef (const Vec3 <double> & aVec)
{
   setX (aVec.getX ());
   setY (aVec.getY ());
   setZ (aVec.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Ecef
////////////////////////////////////////////////////////////////////////////////

Ecef::Ecef (double aX, double aY, double aZ)
{
   setX (aX);
   setY (aY);
   setZ (aZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ~Ecef Destructor
////////////////////////////////////////////////////////////////////////////////

Ecef::~Ecef (void)
{
}

}; // namespace
