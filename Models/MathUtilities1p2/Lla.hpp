////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Lla.hpp
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

#ifndef _LLA_HPP
#define _LLA_HPP

#include "ISEExport.h"
#include "Vec3.hpp"

namespace SamsonMath {

class ISE_Export Lla : public Vec3<double>
{
   private:

   public:

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    Lla
/// Description:  This constructor defines the initial arguments of the Lla function.
////////////////////////////////////////////////////////////////////////////////

   Lla (const Vec3<double> & aRhs);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    Lla
/// Description:  The constructor for this class that initializes the arguments.
//  Inputs:       aLatitude
//                aLongitude
//                aAltitude
// Outputs:       None
////////////////////////////////////////////////////////////////////////////////

   Lla (const double aLatitude = 0.0, const double aLongitude = 0.0, const double aAltitude = 0.0);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getLatitude
/// Description:  This function gets the Latitude.
//  Inputs:       None
//  Output:       Latitude
////////////////////////////////////////////////////////////////////////////////

   inline double getLatitude (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setLatitude
/// Description:  This function sets the Latitude.
//  Inputs:       aLatitude
//  Output:       none
////////////////////////////////////////////////////////////////////////////////

   inline void setLatitude (const double aLatitude);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getLongitude
/// Description:  This function gets the Longitude.
//  Inputs:       None
//  Output:       Longitude
////////////////////////////////////////////////////////////////////////////////

   inline double getLongitude (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setLongitude
/// Description:  This function sets the Longitude
//  Inputs:       aLongitude
//  Output:       none
////////////////////////////////////////////////////////////////////////////////

   inline void setLongitude (const double aLongitude);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getAltitude
/// Description:  This function gets the Altitude
//  Inputs:       None
//  Output:       Altitude
////////////////////////////////////////////////////////////////////////////////

   inline double getAltitude (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setAltitude
/// Description:  This function sets the Longitude.
//  Inputs:       aAltitude
//  Output:       none
////////////////////////////////////////////////////////////////////////////////

   inline void setAltitude (const double aAltitude);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ~Lla
/// Description:  This is the destructor for the Lla class.
////////////////////////////////////////////////////////////////////////////////

      ~Lla ();
};

}; // namespace

#include "Lla.ipp"
#endif
