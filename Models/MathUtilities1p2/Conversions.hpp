////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Conversions.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      The conversion class provides general conversions between
//                   and among the different coordinate systems.
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

#ifndef _CONVERSIONS_HPP
#define _CONVERSIONS_HPP

#include <cmath>
#include "Lla.hpp"
#include "Ecef.hpp"
#include "Eci.hpp"
#include "Ned.hpp"
#include "EulerAngles.hpp"
#include "EulerMatrix.hpp"
#include "Matrix.hpp"
#include "Vec3.hpp"
#include "Quaternion.hpp"

/// Conversion Class.

namespace SamsonMath {

template <class T>
class Conversions
{
   private:

   public:

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    Conversions
/// Description:  Basic constructor for conversions.
////////////////////////////////////////////////////////////////////////////////

      Conversions ();

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefToLla
/// Description:  This function converts a position in ECEF coordinates to Lla.
//  Inputs:       aEcef
//  Returns:      Lla
////////////////////////////////////////////////////////////////////////////////

      Lla ecefToLla (const Ecef & aEcef);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    llaToEcef
/// Description:  This function converts a position in Lla coordinates to ECEF.
//  Inputs:       aLla
//  Returns:      Ecef
////////////////////////////////////////////////////////////////////////////////

      Ecef llaToEcef (const Lla & aLla);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefToNedMatrix
/// Description:  This function converts a position in ECEF coordinates to a
///               Ned Matrix.
//  Inputs:       aLla
//  Returns:      Matrix
////////////////////////////////////////////////////////////////////////////////

      Matrix <T> ecefToNedMatrix (const Lla & aLla);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefToNedPos
/// Description:  This function converts a position in ECEF coordinates to Ned.
//  Inputs:       ecefPosition
//                aEcefToNedMatrix
//                ecefReference
//  Returns:      Ned
////////////////////////////////////////////////////////////////////////////////

      Ned ecefToNedPos (
            const Ecef & aEcefPosition,
            const Matrix <T> & aEcefToNedMatrix,
            const Ecef & aEcefReference);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefToNedVel
/// Description:  This function converts a velocity in ECEF coordinates to Ned.
//  Inputs:       ecefVelocity
//                aEcefToNedMatrix
//  Returns:      Ned
////////////////////////////////////////////////////////////////////////////////

      Ned ecefToNedVel (const Ecef & aEcefVelocity, const Matrix <T> & aEcefToNedMatrix);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    nedToEcefPos
/// Description:  This function converts a position in Ned coordinates to ECEF.
//  Inputs:       aNedPosition
//                aEcefToNedMAtrix
//                aEcefReference
//  Returns:      Ecef
////////////////////////////////////////////////////////////////////////////////

      Ecef nedToEcefPos (
            const Ned & aNedPosition,
            const Matrix<T> & aEcefToNedMatrix,
            const Ecef aEcefReference);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    nedToEcefVel
/// Description:  This function converts a velocity in Ned coordinates to ECEF.
//  Inputs:       aNedVelocity
//                aEcefToNedMatrix
//  Returns:      Ecef
////////////////////////////////////////////////////////////////////////////////

      Ecef nedToEcefVel (const Ned & aNedVelocity, const Matrix<T> & aEcefToNedMatrix);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    dmsToRadians
/// Description:  This function converts a velocity in Dms to Radians.
//  Inputs:       dmsArray
//  Returns:      radians in type T
////////////////////////////////////////////////////////////////////////////////

      T dmsToRadians (const Vec3<T> aDmsArray);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    radiansToDms
/// Description:  This function converts a radians to Dms.
//  Inputs:       inputRadians
//  Returns:      Vec3<T>
////////////////////////////////////////////////////////////////////////////////

      Vec3<T> radiansToDms (const T aInputRadians);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    max
/// Description:  This function finds the maximum of two given values.
//  Inputs:       aX
//                aY
//  Returns:      T
////////////////////////////////////////////////////////////////////////////////

	  T maxa (const T aX, const T aY) { return (aX > aY) ? aX : aY; }

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    min
/// Description:  This function finds the minimum of two given values.
//  Inputs:       aX
//                aY
//  Returns:      T
////////////////////////////////////////////////////////////////////////////////

      T mina (const T aX, const T aY) { return (aX < aY) ? aX : aY; }

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    eulerAnglesToMatrix
/// Description:  This function converts Euler angles to a Euler matrix.
//  Inputs:       aEulerAngles
//  Returns:      EulerMatrix
////////////////////////////////////////////////////////////////////////////////

      EulerMatrix eulerAnglesToMatrix (const EulerAngles & aEulerAngles);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    eulerMatrixToAngles
/// Description:  This function converts a Euler matrix to Euler angles.
//  Inputs:       aEulerMatrix
//  Returns:      EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles eulerMatrixToAngles (Matrix<T> & aEulerMatrix);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    bodyRatesToEulerRates
/// Description:  This function converts the rate of rotation from the body
///               frame of the object in motion to Euler rates.
//  Inputs:       aBodyRates
//                aEulerAngles
//  Returns:      EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles bodyRatesToEulerRates (
            const EulerAngles & aBodyRates,
            const EulerAngles & aEulerAngles);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    eulerRatesToBodyRates
/// Description:  This function converts the Euler rates of an object in motion
///               to the rate of rotation from the body frame.
//  Inputs:       aEulerAngles
//                aEulerRates
//  Returns:      EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles eulerRatesToBodyRates (
            const EulerAngles & aEulerAngles,
            const EulerAngles & aEulerRates);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionToMatrixType
// Description:  This function converts a quaternion to a Matrix.
// Inputs:       aQuat
// Returns:      Matrix
////////////////////////////////////////////////////////////////////////////////

      Matrix<T> quaternionToMatrix (const Quaternion<T> & aQuat);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    eulerToMatrixType
// Description:  This function converts euler to Quaternion.
// Inputs:       aEulerAngles
// Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> eulerToQuaternion (const EulerAngles & aEulerAngles);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionToEuler
// Description:  This function converts quaternion to Euler.
// Inputs:       aQuat
// Returns:      EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles quaternionToEuler (const Quaternion<T> & aQuat);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    bodyRatesToQuaternionRates
// Description:  This function converts body rates to quaternion rates.
// Inputs:       aQuat
//               aPqr
// Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> bodyRatesToQuaternionRates (
            const Quaternion<T> & aQuat,
            Vec3<T> & aPqr);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionRateToBodyRates
// Description:  This function converts quaternion rates to body rates.
// Inputs:       aQuatRate
//               aQuat
// Returns:      aQuatRate
////////////////////////////////////////////////////////////////////////////////

      Vec3<T> quaternionRateToBodyRates (
            const Quaternion<T> & aQuatRate,
            const Quaternion<T> & aQuat);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    matrixToQuaternion
// Description:  This function converts a matrix to a quaternion.
// Inputs:       aMatrix
// Output:       Quaternion
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> matrixToQuaternion (Matrix<T> & aMatrix);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionNedWrtEcef
// Description:  This function converts a matrix to a quaternion
// Inputs:       Lla
// Output:       quatNedWrtEcef
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> quaternionNedWrtEcefLla (const Lla & aLla);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionNedWrtEcefEcef
// Description:  This function converts
// Inputs:       aEcefRef
// Output:       quatNedWrtEcef
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> quaternionNedWrtEcefEcef (const Ecef & aEcefRef);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionEcefWrtNedLla
// Description:  This function converts.
// Inputs:       Lla
// Output:       quatEcefWrtNed
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> quaternionEcefWrtNedLla (const Lla & aLla);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ecefQuaternionToEulerQuat
// Description:  This function converts an Ecef quaternion to an euler quaternion.
// Inputs:       quatEcefWrtNed
//               aQuatBodyFrdWrtEcef
// Output:       EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles ecefQuaternionToEulerQuat (
            const Quaternion<T> & aQuatEcefWrtNed,
            const Quaternion<T> & aQuatBodyFrdWrtEcef);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ecefQuaternionToEulerLla
// Description:  This function converts an Ecef Quaternion to euler Lla.
// Inputs:       aLLA
//               aQuatBodyFrdWrtEcef
// Output:       EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles ecefQuaternionToEulerLla (
            const Vec3<T> & aLla,
            const Quaternion<T> & aQuatBodyFrdWrtEcef);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ecefQuaternionToEulerEcef
// Description:  This function converts an Ecef quaternion to euler Ecef.
// Inputs:       aEcefRef
//               aQuatBodyFrdWrtEcef
// Output:       EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles ecefQuaternionToEulerEcef (
            const Ecef & aEcefRef,
            const Quaternion<T> & aQuatBodyFrdWrtEcef);

/// On these functions, the last abbreviation tells what is input.
/// This function takes takes a Lla input

////////////////////////////////////////////////////////////////////////////////
// Procedure:    quaternionEcefWrtNedEcef
// Description:  This function converts.
// Inputs:       ECEFRef
// Output:       Quaternion
////////////////////////////////////////////////////////////////////////////////

      Quaternion<T> quaternionEcefWrtNedEcef (const Ecef & aEcefRef);

////////////////////////////////////////////////////////////////////////////////
// Procedure:    ecefQuaternionToEulerQuatType
// Description:  This function converts.
// Inputs:       quatEcefWrtNed
//               aQuatBodyFrdWrtEcef
// Output:       EulerAngles
////////////////////////////////////////////////////////////////////////////////

      EulerAngles ecefQuaternionToEulerQuatType (
            const Quaternion <T> & aQuatEcefWrtNed,
            Quaternion <T> & aQuatBodyFrdWrtEcef);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefStatesToEci
/// Description:  This function will convert an ecef state to eci.
//  Inputs:       aPositionEcef
//                aVelocityEcef
//                time
//  Output:       aPositionEci
//                aVelocityEci
////////////////////////////////////////////////////////////////////////////////

   void ecefStatesToEci (
         const double aTime,
         const Ecef aPositionEcef,
         const Ecef aVelocityEcef,
         Eci & aPositionEci,
         Eci & aVelocityEci);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    eciStatesToEcef
/// Description:  This function will convert an eci state to ecef.
//  Inputs:       aPositionEci
//                aVelocityEci
//                time
//  Output:       aPositionEcef
//                aVelocityEcef
////////////////////////////////////////////////////////////////////////////////

   void eciStatesToEcef (
         const double aTime,
         const Eci aPositionEci,
         const Eci aVelocityEci,
         Ecef & aPositionEcef,
         Ecef & aVelocityEcef);


////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ecefToEciDcm
/// Description:  This function will convert Ecef to Eci DCM
//  Inputs:       time
////////////////////////////////////////////////////////////////////////////////

   Matrix<T> ecefToEciDcm (const double aTime);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ~Conversions
/// Description:  Basic destructor for conversions.
////////////////////////////////////////////////////////////////////////////////

   ~Conversions ();
};

} // namespace

#include "Conversions.ipp"
#endif
