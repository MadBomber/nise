////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Eci.cpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Eci.
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

#include "Eci.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Eci Constructor
////////////////////////////////////////////////////////////////////////////////

Eci::Eci (const Vec3 <double> & aVec)
{
   setX (aVec.getX ());
   setY (aVec.getY ());
   setZ (aVec.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Eci
////////////////////////////////////////////////////////////////////////////////

Eci::Eci (const double aX, const double aY, const double aZ)
{
   setX (aX);
   setY (aY);
   setZ (aZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:   getEciGravity
// Description: Get Eci Gravity Vector from Lla and ECI positions
////////////////////////////////////////////////////////////////////////////////
Eci Eci::getEciGravity (const Lla aRhs, const double aTime)
{
   const double cosLatitude  = cos (aRhs.getLatitude  ());
   const double sinLatitude  = sin (aRhs.getLatitude  ());
   const double cosLongitude = cos (aRhs.getLongitude () + OMEGA_EARTH * aTime);
   const double sinLongitude = sin (aRhs.getLongitude () + OMEGA_EARTH * aTime);

   // Gravity at inertial location
   const double dotPositionEci = *this ^ *this;
   const double temporary = GRAV_CONST * EARTH_MASS / dotPositionEci;
   const double eta = EQUATOR_RADIUS*EQUATOR_RADIUS / dotPositionEci;
   const double ggcn = -3 * temporary * eta * RJ2 * sinLatitude * cosLatitude;
   const double ggcd = temporary * (1.0 + 3.0 * RJ2 * eta * 0.5 * ( 1.0 - 3.0 * sinLatitude * sinLatitude ));
   Eci gravityEci;

   gravityEci.setX (ggcn * cosLatitude - ggcd * sinLatitude);
   gravityEci.setY (-ggcn * sinLongitude * sinLatitude - ggcd * sinLongitude * cosLatitude);
   gravityEci.setZ (ggcn * cosLongitude * sinLatitude + ggcd * cosLongitude * cosLatitude);

   return gravityEci;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ~Eci Destructor
////////////////////////////////////////////////////////////////////////////////

Eci::~Eci (void)
{
}

}; // namepace
