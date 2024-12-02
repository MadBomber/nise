////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Constants.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      MEADS Simulation
//
// Description:      This file contains a list of commonly used constants.
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

#ifndef _CONSTANTS_HPP
#define _CONSTANTS_HPP

#include "ISEExport.h"
#include <math.h>

namespace SamsonMath {

// World Geodetic System 1984, Earth Model Parameters
// Earth Ellipsoid Semi Major Axis (m^2)
const double EQUATOR_RADIUS            = 6378137.0;

// Earth Ellipsoid Semi Major Axis Squared (m^2)
const double EQUATOR_RADIUS_2          = EQUATOR_RADIUS * EQUATOR_RADIUS;

// Earth Ellipsoid Flattening 
const double ELLIPSOID_FLATTENING      = 1.0 / 298.257223563;

// Earth Ellipsoid Semi Minor Axis (m)
const double POLAR_RADIUS              = EQUATOR_RADIUS * (1 - ELLIPSOID_FLATTENING);

// Earth Ellipsoid Semi Minor Axis Squared (m^2)
const double POLAR_RADIUS_2            = POLAR_RADIUS * POLAR_RADIUS;

// Ellipsoid First Eccentricity
const double FIRST_ECCENTRICITY        = sqrt ((EQUATOR_RADIUS_2 - POLAR_RADIUS_2)
                                               / EQUATOR_RADIUS_2);

// Ellipsoid Second Eccentricity
const double SECOND_ECCENTRICITY       = sqrt ((EQUATOR_RADIUS_2 - POLAR_RADIUS_2)
                                               / POLAR_RADIUS_2);

// Ellipsoid First Eccentricity Squared
const double FIRST_ECCENTRICITY_2      = FIRST_ECCENTRICITY * FIRST_ECCENTRICITY;

// Ellipsoid Second Eccentricity Squared
const double SECOND_ECCENTRICITY_2     = SECOND_ECCENTRICITY * SECOND_ECCENTRICITY;

// Earth Rotation Angular Velocity (rad/s)
const double OMEGA_EARTH               = 0.00007292115;

// Ratio of the circumference to the diameter of a circle
const double PI                        = 3.1415926535897932384626433832795;

// Twice the ratio of the circumference to the diameter of a circle
const double TWO_PI                    = 2.0 * PI;

// Half of the ratio of the circumference to the diameter of a circle
const double PI_OVER_TWO               = PI / 2.0;

// Conversion from Degrees to Radians
const double DEG_TO_RAD                = PI / 180.0;

// Conversion from Radians to Degrees
const double RAD_TO_DEG                = 180.0 / PI;

// Square Root of 2
const double SQRT_TWO                  = 1.41421356237309504880168872421;

// Square Root of 2 over 2 
const double SQRT_TWO_OVER_TWO         = SQRT_TWO / 2.0;

// Universal Gravitational Constant (m^3/(kg*s^2))
const double GRAV_CONST                = 6.673e-11;

// Mass of the Earth (kg)
const double EARTH_MASS                = 5.9763e24;

// Second order Jeffery coefficient 
const double RJ2                       = 0.00108261579;

// One Half
const double ONE_HALF                  = 1.0 / 2.0;

// One Fourth
const double ONE_FOURTH                = 1.0 / 4.0;

// Minimum value allowed for divisions
const double EPSILON                   = 1e-12;

// Conversion from meters to kilometers
const double M_TO_KM                   = 1.0 / 1000.0;

// Conversion from kilometers to meters
const double KM_TO_M                   = 1000.0;

}  // namespace 

#endif
