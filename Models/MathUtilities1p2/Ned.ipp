////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Ned.ipp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      MEADS Simulation
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

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getNorth
////////////////////////////////////////////////////////////////////////////////

inline double Ned::getNorth (void) const
{
   return getX ();
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setNorth
////////////////////////////////////////////////////////////////////////////////

inline void Ned::setNorth (const double aNorth)
{
   setX (aNorth);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getEast
/////////////////////////////////////////////////////////////////////////////////

inline double Ned::getEast (void) const
{
   return getY ();
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setEast
/////////////////////////////////////////////////////////////////////////////////

inline void Ned::setEast (const double aEast)
{
   setY (aEast);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getDown
////////////////////////////////////////////////////////////////////////////////

inline double Ned::getDown (void) const
{
   return getZ ();
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setDown
////////////////////////////////////////////////////////////////////////////////


inline void Ned::setDown (const double aDown)
{
   setZ (aDown);
}



}; // namespace
