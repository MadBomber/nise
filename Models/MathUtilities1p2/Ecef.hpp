////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Ecef.hpp
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

#ifndef _ECEF_HPP
#define _ECEF_HPP


#include "ISEExport.h"
#include "Vec3.hpp"

namespace SamsonMath {

/// ECEF Class.

/// This class is derived from the Vec3 class
/// and has arguments X, Y, and Z.

class ISE_Export Ecef : public Vec3<double>
{
   public:

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Ecef (Constructor)
      /// Description:  Accept each argument, defaulting each to 0
      // Inputs:        aX
      //                aY
      //                aZ
      // Outputs:       Initializes aX, aY, aZ to zero.
      ////////////////////////////////////////////////////////////////////////////////

      Ecef (double aX = 0.0, double aY = 0.0, double aZ = 0.0);

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Ecef
      /// Description:  Copy constructor
      // Inputs:        aVec
      // Output:        Ecef
      ////////////////////////////////////////////////////////////////////////////////

      Ecef (const Vec3<double> & aVec);

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Ecef
      /// Description:  The destructor for this class.
      ////////////////////////////////////////////////////////////////////////////////

      ~Ecef ();

   private:
};

}; // namepace

#endif
