////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Eci.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Eci.
//
// Author:           Hector L. Bayona
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

#ifndef _ECI_HPP
#define _ECI_HPP

#include "ISEExport.h"
#include "Vec3.hpp"
#include "Lla.hpp"

namespace SamsonMath {

/// ECI Class.

/// This class is derived from the Vec3 class
/// and has arguments X, Y, and Z.

class ISE_Export Eci : public Vec3<double>
{
   public:

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Eci (Constructor)
      /// Description:  Accept each argument, defaulting each to 0
      // Inputs:        aX
      //                aY
      //                aZ
      // Outputs:       None
      ////////////////////////////////////////////////////////////////////////////////

      Eci (const double aX = 0.0, const double aY = 0.0, const double aZ = 0.0);

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Eci
      /// Description:  Copy constructor
      // Inputs:        aVec
      // Output:        None
      ////////////////////////////////////////////////////////////////////////////////

      Eci (const Vec3<double> & aVec);

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:     Eci
      /// Description:  The destructor for this class.
      ////////////////////////////////////////////////////////////////////////////////

      ~Eci ();

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:   getEciGravity
      // Description: Get Eci Gravity Vector from Lla and ECI positions
      // Inputs:      aRhs - Lla position
      //              aTime - since ECEF equaled ECI
      // Returns:     Eci - gravity
      ////////////////////////////////////////////////////////////////////////////////

      Eci getEciGravity (const Lla aRhs, const double aTime);

   private:
};

}; // namespace
#endif
