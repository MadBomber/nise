////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Conversions.ipp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      MEADS Simulation
//
// Description:      This file contains the class definition  of Conversions.
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
// <yyyymmdd> <Eng> <Description of modification>
//  20051114   HLB   Originial Release
//
////////////////////////////////////////////////////////////////////////////////

#include <math.h>
#include "Vec3.hpp"
#include "Matrix.hpp"
#include "Constants.hpp"
#include "EulerAngles.hpp"
#include "EulerMatrix.hpp"

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Conversions (Constructor)
////////////////////////////////////////////////////////////////////////////////

template <class T>
Conversions <T>::Conversions (void)
{
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefToLla
////////////////////////////////////////////////////////////////////////////////

template <class T>
Lla Conversions <T>::ecefToLla (const Ecef & aEcef)
{
   Lla lla;
   const double p = sqrt(aEcef.getX () * aEcef.getX () + aEcef.getY () * aEcef.getY ());
   const double theta = atan2(aEcef.getZ () * EQUATOR_RADIUS, p * POLAR_RADIUS);
   const double sinThetaCube = sin(theta) * sin(theta) * sin(theta);
   const double cosThetaCube = cos(theta) * cos(theta) * cos(theta);
   
   lla.setLongitude (atan2(aEcef.getY () , aEcef.getX ()));
   lla.setLatitude (atan2(aEcef.getZ () + SECOND_ECCENTRICITY_2 * POLAR_RADIUS * sinThetaCube ,
         p - FIRST_ECCENTRICITY_2 * EQUATOR_RADIUS * cosThetaCube));
   const double denCurvature = sqrt (1 - FIRST_ECCENTRICITY_2 *
                  sin (lla.getLatitude ()) * sin (lla.getLatitude ()));
   const double radiusOfCurvature = EQUATOR_RADIUS / denCurvature;

   lla.setAltitude ((p/cos(lla.getLatitude ())) - radiusOfCurvature);
   
   return lla;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  llaToEcef
////////////////////////////////////////////////////////////////////////////////

template <class T>
Ecef Conversions <T>::llaToEcef (const Lla & aLla)
{
   const double sinLatitude = sin (aLla.getLatitude ());
   const double cosLatitude = cos (aLla.getLatitude ());
   const double denCurvature = sqrt (1 - FIRST_ECCENTRICITY_2 *
                     sinLatitude * sinLatitude);
   if (denCurvature > EPSILON )
   {
      const double radiusOfCurvature = EQUATOR_RADIUS / denCurvature;
      const double temp = (radiusOfCurvature + aLla.getAltitude ()) * cosLatitude; 
      return Ecef (temp * cos (aLla.getLongitude ()), 
                  temp * sin (aLla.getLongitude ()),
                  ((POLAR_RADIUS_2 / EQUATOR_RADIUS_2) * radiusOfCurvature +
                  aLla.getAltitude ()) * sinLatitude);
   }
   else
   {
      std::cerr << "Division by 0 not Allowed ::llaToEcef" << endl;
      return Ecef (0, 0 ,0);
   }      
     
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefToNedMatrix
////////////////////////////////////////////////////////////////////////////////

template <class T>
Matrix <T> Conversions <T> :: ecefToNedMatrix (const Lla & aLla)
{
   T cosLatitude;
   T cosLongitude;
   T sinLatitude;
   T sinLongitude;

   Matrix<T> nedMatrix;

   cosLatitude  = cos (aLla.getLatitude  ());
   cosLongitude = cos (aLla.getLongitude ());
   sinLatitude  = sin (aLla.getLatitude  ());
   sinLongitude = sin (aLla.getLongitude ());

   nedMatrix.setRow (1, Vec3<T> (-sinLatitude * cosLongitude, -sinLatitude * sinLongitude, cosLatitude));
   nedMatrix.setRow (2, Vec3<T> (-sinLongitude, cosLongitude, 0.0));
   nedMatrix.setRow (3, Vec3<T> (-cosLatitude * cosLongitude, -cosLatitude * sinLongitude, -sinLatitude));

   return nedMatrix;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  nedToEcefPos
////////////////////////////////////////////////////////////////////////////////


template <class T>
Ecef Conversions <T> :: nedToEcefPos (
      const Ned & aNedPosition,
      const Matrix<T> & aEcefToNedMatrix,
      const Ecef aEcefReference)
{
   Ecef ecefPosition;

   ecefPosition.setX (
         aEcefToNedMatrix.getRow (0).getX () * aNedPosition.getNorth () +
         aEcefToNedMatrix.getRow (0).getY () * aNedPosition.getEast () +
         aEcefToNedMatrix.getRow (0).getZ () * aNedPosition.getDown () +
         aEcefReference.getX ());

   ecefPosition.setY (
         aEcefToNedMatrix.getRow (1).getX () * aNedPosition.getNorth () +
         aEcefToNedMatrix.getRow (1).getY () * aNedPosition.getEast () +
         aEcefToNedMatrix.getRow (1).getZ () * aNedPosition.getDown () +
         aEcefReference.getY ());

   ecefPosition.setZ (
         aEcefToNedMatrix.getRow (2).getX () * aNedPosition.getNorth () +
         aEcefToNedMatrix.getRow (2).getY () * aNedPosition.getEast () +
         aEcefToNedMatrix.getRow (2).getZ () * aNedPosition.getDown () +
         aEcefReference.getZ ());

   return ecefPosition;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  nedToEcefVel
////////////////////////////////////////////////////////////////////////////////

template <class T>
Ecef Conversions <T> :: nedToEcefVel (const Ned & aNedVelocity, const Matrix<T> & aEcefToNedMatrix)
{
   Ecef ecefVelocity;

   ecefVelocity.setX (
         aEcefToNedMatrix.getRow (0).getX () * aNedVelocity.getNorth () +
         aEcefToNedMatrix.getRow (0).getY () * aNedVelocity.getEast () +
         aEcefToNedMatrix.getRow (0).getZ () * aNedVelocity.getDown ());

   ecefVelocity.setY (
         aEcefToNedMatrix.getRow (1).getX () * aNedVelocity.getNorth () +
         aEcefToNedMatrix.getRow (1).getY () * aNedVelocity.getEast () +
         aEcefToNedMatrix.getRow (1).getZ () * aNedVelocity.getDown ());

   ecefVelocity.setZ (
         aEcefToNedMatrix.getRow (2).getX () * aNedVelocity.getNorth () +
         aEcefToNedMatrix.getRow (2).getY () * aNedVelocity.getEast () +
         aEcefToNedMatrix.getRow (2).getZ () * aNedVelocity.getDown ());

   return ecefVelocity;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefToNedPos
////////////////////////////////////////////////////////////////////////////////

template <class T>
Ned Conversions <T> :: ecefToNedPos (
      const Ecef       & aEcefPosition,
      const Matrix <T> & aEcefToNedMatrix,
      const Ecef       & aEcefReference)
{
   Ecef ecefRelative;
   Ned nedPosition;

   ecefRelative = aEcefPosition - aEcefReference;

   nedPosition.setNorth (
         aEcefToNedMatrix.getRow (0).getX () * ecefRelative.getX () +
         aEcefToNedMatrix.getRow (0).getY () * ecefRelative.getY () +
         aEcefToNedMatrix.getRow (0).getZ () * ecefRelative.getZ ());

   nedPosition.setEast (
         aEcefToNedMatrix.getRow (1).getX () * ecefRelative.getX () +
         aEcefToNedMatrix.getRow (1).getY () * ecefRelative.getY () +
         aEcefToNedMatrix.getRow (1).getZ () * ecefRelative.getZ ());

   nedPosition.setDown (
         aEcefToNedMatrix.getRow (2).getX () * ecefRelative.getX () +
         aEcefToNedMatrix.getRow (2).getY () * ecefRelative.getY () +
         aEcefToNedMatrix.getRow (2).getZ () * ecefRelative.getZ ());

   return nedPosition;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefToNedVel
////////////////////////////////////////////////////////////////////////////////

template <class T>
Ned Conversions <T> :: ecefToNedVel (
      const Ecef & aEcefVelocity,
      const Matrix <T> & aEcefToNedMatrix)
{
   
   Ned nedVelocity;
   nedVelocity.setNorth (
         aEcefToNedMatrix.getRow (0).getX () * aEcefVelocity.getX () +
         aEcefToNedMatrix.getRow (0).getY () * aEcefVelocity.getY () +
         aEcefToNedMatrix.getRow (0).getZ () * aEcefVelocity.getZ ());

   nedVelocity.setEast (
         aEcefToNedMatrix.getRow (1).getX () * aEcefVelocity.getX () +
         aEcefToNedMatrix.getRow (1).getY () * aEcefVelocity.getY () +
         aEcefToNedMatrix.getRow (1).getZ () * aEcefVelocity.getZ ());

   nedVelocity.setDown (
         aEcefToNedMatrix.getRow (2).getX () * aEcefVelocity.getX () +
         aEcefToNedMatrix.getRow (2).getY () * aEcefVelocity.getY () +
         aEcefToNedMatrix.getRow (2).getZ () * aEcefVelocity.getZ ());

   return nedVelocity;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  dmsToRadians
////////////////////////////////////////////////////////////////////////////////

template <class T>
T Conversions <T> :: dmsToRadians (const Vec3<T> aDmsArray)
{
   T radians;

   if (aDmsArray.getX () >= EPSILON)
   {
      radians = PI * (aDmsArray.getX () + aDmsArray.getY () / 60.0 + aDmsArray.getZ () / 3600.0);
   }
   else
   {
      radians = PI * (aDmsArray.egtX () - aDmsArray.getY () / 60.0 - aDmsArray.getZ () / 3600.0);
   }
   return radians;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  radiansToDms
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3 <T> Conversions <T> :: radiansToDms (const T aInputRadians)
{
   Vec3<T> dmsArray;
   T inputDegreesMag;
   T degrees;
   T minutes;
   T seconds;

   inputDegreesMag = fabs (aInputRadians * 180.0 / PI);
   degrees = abs (inputDegreesMag);
   minutes = abs (60.0 * (inputDegreesMag - degrees));
   seconds = 3600.0 * (inputDegreesMag - degrees - minutes / 60.0);

   if (aInputRadians < EPSILON)
   {
      dmsArray.setX (-1.0 * degrees);
   }
   else
   {
      dmsArray.setX (degrees);
   }
   dmsArray.setY (minutes);
   dmsArray.setZ (seconds);

   return dmsArray;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  max
////////////////////////////////////////////////////////////////////////////////
/*
template <class T>
T Conversions <T>::max (const T aX, const T aY)
{
   if (aX > aY)
   {
      return aX;
   }
   else
   {
      return aY;
   }
}
*/
////////////////////////////////////////////////////////////////////////////////
// Procedure:  min
////////////////////////////////////////////////////////////////////////////////
/*
template <class T>
T Conversions <T>::min (const T aX, const T aY)
{
   if (aX < aY)
   {
      return aX;
   }
   else
   {
      return aY;
   }
}
*/
////////////////////////////////////////////////////////////////////////////////
// Procedure:  eulerAnglesToMatrix
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerMatrix Conversions<T>::eulerAnglesToMatrix (const EulerAngles & aEulerAngles)
{
   T cosPhi;
   T sinPhi;
   T cosTheta;
   T sinTheta;
   T cosPsi;
   T sinPsi;

   EulerMatrix eulerMatrix;

   cosPhi   = cos (aEulerAngles.getRoll  ());
   sinPhi   = sin (aEulerAngles.getRoll  ());
   cosTheta = cos (aEulerAngles.getPitch ());
   sinTheta = sin (aEulerAngles.getPitch ());
   cosPsi   = cos (aEulerAngles.getYaw   ());
   sinPsi   = sin (aEulerAngles.getYaw   ());

   eulerMatrix.setRow (0, EulerAngles (cosTheta * cosPsi, cosTheta * sinPsi, -sinTheta));


   eulerMatrix.setRow (1, EulerAngles (
         -cosPhi * sinPsi + sinPhi * sinTheta * cosPsi,
         cosPhi * cosPsi + sinPhi * sinTheta * sinPsi,
         sinPhi * cosTheta));


   eulerMatrix.setRow (2, EulerAngles (
         sinPhi * sinPsi + cosPhi * sinTheta * cosPsi,
         -sinPhi * cosPsi + cosPhi * sinTheta * sinPsi,
         cosPhi * cosTheta));

   return eulerMatrix;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  eulerMatrixToAngles
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions<T>::eulerMatrixToAngles (Matrix <T> & aMatrix)
{
   // ROLL

   EulerAngles eulerAngles;

   if (aMatrix.getRow (2).getZ () != 0.0)
   {
      if (aMatrix.getRow (1).getZ () != 0.0)
      {
         eulerAngles.setRoll (atan2 (aMatrix.getRow (1).getZ (), aMatrix.getRow (2).getZ ()));
      }
      else
      {
         eulerAngles.setRoll (0.0);
      }
   }
   else if (aMatrix.getRow (1).getZ () != 0.0)
   {
      if (aMatrix.getRow (1).getZ () > 0.0)
      {
         eulerAngles.setRoll (PI_OVER_TWO);
      }
      else
      {
         eulerAngles.setRoll (-PI_OVER_TWO);
      }
   }
   else
   {
      eulerAngles.setRoll (0.0);
   }

   // PITCH

   eulerAngles.setPitch (asin (max (-1.0, mina (1.0, -aMatrix.getRow (0).getZ ()))));

   // YAW

   if (aMatrix.getRow (0).getX () != 0.0)
   {
      if (aMatrix.getRow (0).getY () != 0.0)
      {
         eulerAngles.setYaw (atan2 (aMatrix.getRow (0).getY (), aMatrix.getRow (0).getX ()));
      }
      else
      {
         eulerAngles.setYaw (0.0);
      }
   }
   else if (aMatrix.getRow (0).getY () != 0.0)
   {
      if (aMatrix.getRow (0).getY () > 0.0)
      {
         eulerAngles.setYaw (PI_OVER_TWO);
      }
      else
      {
         eulerAngles.setYaw (-PI_OVER_TWO);
      }
   }
   else
   {
      eulerAngles.setYaw (0.0);
   }
   return eulerAngles;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  eulerRatesFromBodyRates
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions <T>::bodyRatesToEulerRates (
      const EulerAngles & aPqr,
      const EulerAngles & aEulerAngles)
{
   EulerAngles eulerRates;

   eulerRates.setYaw   ((aPqr.getPitch () * sin (aEulerAngles.getRoll ()) + aPqr.getYaw () * cos (aEulerAngles.getRoll ())) / (cos (aEulerAngles.getPitch ()) + EPSILON));
   eulerRates.setPitch (aPqr.getPitch () * cos (aEulerAngles.getRoll ()) - aPqr.getYaw () * sin (aEulerAngles.getRoll ()));
   eulerRates.setRoll  (aPqr.getRoll () + aEulerAngles.getYaw () * sin (aEulerAngles.getPitch ()));

   return eulerRates;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  bodyRatesFromEulerRates
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions <T>::eulerRatesToBodyRates (
      const EulerAngles & aEulerAngles,
      const EulerAngles & aEulerRates)
{
   EulerAngles bodyRates;       //P, Q, R

   bodyRates.setRoll (aEulerRates.getRoll () - aEulerRates.getYaw () * sin (aEulerAngles.getPitch ()));

   bodyRates.setPitch (
         aEulerRates.getPitch () * cos (aEulerAngles.getRoll ()) +
         aEulerRates.getYaw () * cos (aEulerAngles.getPitch ()) * sin (aEulerAngles.getRoll ()));

   bodyRates.setYaw (
         aEulerRates.getYaw () * cos (aEulerAngles.getPitch ()) * cos (aEulerAngles.getRoll ()) -
         aEulerRates.getPitch () * sin (aEulerAngles.getRoll ()));

   return bodyRates;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionToMatrixType
////////////////////////////////////////////////////////////////////////////////

template <class T>
Matrix<T> Conversions<T>::quaternionToMatrix (const Quaternion <T> & aQuat)
{
   Matrix<T> aMatrix;
   T q00;
   T q11;
   T q22;
   T q33;
   T q01;
   T q02;
   T q03;
   T q12;
   T q13;
   T q23;

   q00 = aQuat.getQ0 () * aQuat.getQ0 ();
   q11 = aQuat.getQ1 () * aQuat.getQ1 ();
   q22 = aQuat.getQ2 () * aQuat.getQ2 ();
   q33 = aQuat.getQ3 () * aQuat.getQ3 ();
   q01 = aQuat.getQ0 () * aQuat.getQ1 ();
   q02 = aQuat.getQ0 () * aQuat.getQ2 ();
   q03 = aQuat.getQ0 () * aQuat.getQ3 ();
   q12 = aQuat.getQ1 () * aQuat.getQ2 ();
   q13 = aQuat.getQ1 () * aQuat.getQ3 ();
   q23 = aQuat.getQ2 () * aQuat.getQ3 ();

   aMatrix.setRow (0, Vec3<T> (q00 + q11 - q22 - q33, 2.0 * (q12 + q03), 2.0 * (q13 - q02)));
   aMatrix.setRow (1, Vec3<T> (2.0 * (q12 - q03), q00 - q11 + q22 - q33, 2.0 * (q23 + q01)));
   aMatrix.setRow (2, Vec3<T> (2.0 * (q13 + q02), 2.0 * (q23 - q01), q00 - q11 - q22 + q33));

   return aMatrix;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  eulerToQuaternion
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::eulerToQuaternion (const EulerAngles & aEulerAngles)
{
   Quaternion<T> quat;

   T cosYaw2;
   T sinYaw2;

   T cosPitch2;
   T sinPitch2;

   T cosRoll2;
   T sinRoll2;

   cosYaw2   = cos (aEulerAngles.getYaw   () * ONE_HALF);
   sinYaw2   = sin (aEulerAngles.getYaw   () * ONE_HALF);
   cosPitch2 = cos (aEulerAngles.getPitch () * ONE_HALF);
   sinPitch2 = sin (aEulerAngles.getPitch () * ONE_HALF);
   cosRoll2  = cos (aEulerAngles.getRoll  () * ONE_HALF);
   sinRoll2  = sin (aEulerAngles.getRoll  () * ONE_HALF);

   // Quaternion for Body FRD wrt Reference FRD

   quat.setQ0 (cosYaw2 * cosPitch2 * cosRoll2 + sinYaw2 * sinPitch2 * sinRoll2);
   quat.setQ1 (cosYaw2 * cosPitch2 * sinRoll2 - sinYaw2 * sinPitch2 * cosRoll2);
   quat.setQ2 (cosYaw2 * sinPitch2 * cosRoll2 + sinYaw2 * cosPitch2 * sinRoll2);
   quat.setQ3 (cosYaw2 * cosPitch2 * cosRoll2 - cosYaw2 * sinPitch2 * sinRoll2);

   // Normalize quaternion

   quat = quat.normalize ();

   return quat;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionToEuler
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions<T>::quaternionToEuler (const Quaternion <T> & aQuat)
{
   EulerAngles eulerAngles;
   T q00 = aQuat.getQ0 () * aQuat.getQ0 ();
   T q11 = aQuat.getQ1 () * aQuat.getQ1 ();
   T q22 = aQuat.getQ2 () * aQuat.getQ2 ();
   T q33 = aQuat.getQ3 () * aQuat.getQ3 ();
   
   // Euler Angles for Body FRD wrt Reference FRD

   eulerAngles.setRoll (atan2 (2.0 * (aQuat.getQ1 () * aQuat.getQ0 () 
                              + aQuat.getQ2 () * aQuat.getQ3 ()),
                              (q00 - q11 - q22 + q33)));

   eulerAngles.setPitch (asin (maxa (-1.0, mina (1.0,
         -2.0 * (aQuat.getQ1 () * aQuat.getQ3 () - aQuat.getQ0 () * aQuat.getQ2)))));

   eulerAngles.setYaw (atan2 (2.0 * (aQuat.getQ0 () * aQuat.getQ3 ()
                              + aQuat.getQ1 () * aQuat.getQ2 ()),
                              (q00 + q11 - q22 - q33)));

   return eulerAngles;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  bodyRatesToQuaternionRates
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::bodyRatesToQuaternionRates (
      const Quaternion<T> & aQuat,
      Vec3<T> & aPqr)
{
   Quaternion<T> quatRate;

   quatRate.setQ0 (-0.5 * (aPqr.getX () * aQuat.getQ1 () + aPqr.getY () * aQuat.getQ2 () + aPqr.getZ () * aQuat.getQ3 ()));
   quatRate.setQ1 (0.5 * (aPqr.getX () * aQuat.getQ0 () - aPqr.getY () * aQuat.getQ3 () + aPqr.getZ () * aQuat.getQ2 ()));
   quatRate.setQ2 (0.5 * (aPqr.getX () * aQuat.getQ3 () - aPqr.getY () * aQuat.getQ0 () + aPqr.getZ () * aQuat.getQ1 ()));
   quatRate.setQ3 (0.5 * (-aPqr.getX () * aQuat.getQ2 () - aPqr.getY () * aQuat.getQ1 () + aPqr.getZ () * aQuat.getQ0 ()));

   return quatRate;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionRateToBodyRates
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T> Conversions<T>::quaternionRateToBodyRates (
      const Quaternion<T> & aQuatRate,
      const Quaternion<T> & aQuat)
{
   Vec3<T> pqr;

   pqr.setX (-2.0 * (
         -aQuatRate.getQ1 () * aQuat.getQ0 () +
         aQuatRate.getQ0 () * aQuat.getQ1 () +
         aQuatRate.getQ3 () * aQuat.getQ2 () -
         aQuatRate.getQ2 () * aQuat.getQ3 ()));

   pqr.setY (-2.0 * (
         -aQuatRate.getQ2 () * aQuat.getQ0 () -
         aQuatRate.getQ3 () * aQuat.getQ1 () +
         aQuatRate.getQ0 () * aQuat.getQ2 () +
         aQuatRate.getQ1 () * aQuat.getQ3 ()));

   pqr.setZ (-2.0 * (
         -aQuatRate.getQ3 () * aQuat.getQ0 () -
         aQuatRate.getQ2 () * aQuat.getQ1 () +
         aQuatRate.getQ1 () * aQuat.getQ2 () +
         aQuatRate.getQ0 () * aQuat.getQ3 ()));

   return pqr;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  matrixToQuaternion
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::matrixToQuaternion (Matrix<T> & aMatrix)
{
   Quaternion<double> quat;
   EulerAngles eulerAnglesNed;
   Conversions<double> conv;

   eulerAnglesNed = conv.eulerMatrixToAngles (aMatrix);

   quat = conv.eulerToQuaternion (eulerAnglesNed);

   return quat;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionNedWrtEcefLla
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::quaternionNedWrtEcefLla (const Lla & aLla)
{
   T cosLatitude;
   T sinLatitude;

   T cosLongitude;
   T sinLongitude;

   Quaternion<T> quatEciWrtEcef;
   Quaternion<T> quatNedWrtEci;
   Quaternion<T> quatNedWrtEcef;

   // Quaternion for "ECI orientation" wrt Ecef

   quatEciWrtEcef.setQ0 (SQRT_TWO_OVER_TWO);
   quatEciWrtEcef.setQ1 (0.0);
   quatEciWrtEcef.setQ2 (-SQRT_TWO_OVER_TWO);
   quatEciWrtEcef.setQ3 (0.0);

   cosLatitude  = cos (aLla.getLatitude  () * ONE_HALF);
   sinLatitude  = sin (aLla.getLatitude  () * ONE_HALF);
   cosLongitude = cos (aLla.getLongitude () * ONE_HALF);
   sinLongitude = sin (aLla.getLongitude () * ONE_HALF);

   quatNedWrtEci.setQ0 (cosLatitude  * cosLongitude);
   quatNedWrtEci.setQ1 (cosLatitude  * sinLongitude);
   quatNedWrtEci.setQ2 (-sinLatitude * cosLongitude);
   quatNedWrtEci.setQ3 (-sinLatitude * sinLongitude);

   // Quaternion for reference Ned wrt Ecef

   quatEciWrtEcef.QuaternionMultiply (quatNedWrtEci, quatNedWrtEcef);

   return quatNedWrtEcef;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionNedWrtEcefEcef
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::quaternionNedWrtEcefEcef (const Ecef & aEcefRef)
{
   Conversions<T> conv;
   Lla lla;
   Quaternion<T> quatNedWrtEcef;

   // Lla Position from Ecef reference input

   lla = conv.EcefToLla (aEcefRef);

   // Quaternion for reference Ned wrt Ecef

   quatNedWrtEcef = conv.quaternionNedWrtEcefLla (lla);

   return quatNedWrtEcef;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  quaternionEcefWrtNedLla
////////////////////////////////////////////////////////////////////////////////

template <class T>
Quaternion<T> Conversions<T>::quaternionEcefWrtNedLla (const Lla & aLla)
{
   Quaternion<T>  quatEcefWrtNed;
   Quaternion<T>  quatNedWrtEcef;
   Conversions<T> conv;
   Quaternion<T>  quat;

   // Quaternion for local Ned wrt Ecef

   quatNedWrtEcef = conv.quaternionNedWrtEcefLla (aLla);

   // Quaternion for Ecef wrt reference Ned (needed to get euler angles)

   quatEcefWrtNed = quat.QuaternionInverse (quatNedWrtEcef);

   return quatEcefWrtNed;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefQuaternionToEulerQuat
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions<T>::ecefQuaternionToEulerQuat (
      const Quaternion<T> & aQuatEcefWrtNed,
      const Quaternion<T> & aQuatBodyFrdWrtEcef)
{
   Quaternion<T> quatBodyFRDwrtNED;

   // Quaternion for body FRD wrt reference Ned

   // quatBodyFrdWrtNed = quatEcefWrtNed .QMULT. quatBodyFrdWrtEcef

   aQuatEcefWrtNed.QuaternionMultiply (aQuatBodyFrdWrtEcef, quatBodyFRDwrtNED);

   // Body Ned Euler angles

   return (quaternionToEuler (quatBodyFRDwrtNED));
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefQuaternionToEulerLla
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions<T>::ecefQuaternionToEulerLla (
      const Vec3<T> & aLla,
      const Quaternion<T> & aQuatBodyFrdWrtEcef)
{
   Quaternion<T>  quatEcefWrtNed;
   Conversions<T> conv;

   // Quaternion for Ecef wrt reference Ned

   quatEcefWrtNed = conv.quaternionEcefWrtNedLla (aLla);

   // Body Ned Euler angles

   return (ecefQuaternionToEulerQuat (quatEcefWrtNed , aQuatBodyFrdWrtEcef));   // JKL...changes for compile only, HELP!

}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ecefQuaternionToEulerEcef
////////////////////////////////////////////////////////////////////////////////

template <class T>
EulerAngles Conversions<T>::ecefQuaternionToEulerEcef (
      const Ecef & aEcefRef,
      const Quaternion<T> & aQuatBodyFrdWrtEcef)
{
   Lla lla;
   Conversions<T> conv;

   // Lla position from Ecef reference input

   lla = conv.EcefToLla (aEcefRef);

   // Body Ned Euler angles

   return (ecefQuaternionToEulerLla (lla, aQuatBodyFrdWrtEcef));

}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Ecef to Eci
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Conversions <T>::ecefStatesToEci (
      const double aTime,
      const Ecef aPositionEcef,
      const Ecef aVelocityEcef,
      Eci & aPositionEci,
      Eci & aVelocityEci)
{
   Eci omegaCrossPositionEci;
   Vec3<double> omegaEarthVector (0.0, 0.0, OMEGA_EARTH);
   Matrix <double> rotateEcefToEci;

   double omegaTime = OMEGA_EARTH * aTime;
   double sinOmegaTime = sin (omegaTime);
   double cosOmegaTime = cos (omegaTime);

   //Calculating Ecef to Eci DCM
   rotateEcefToEci.setRow (0, cosOmegaTime, -sinOmegaTime, 0.0);
   rotateEcefToEci.setRow (1, sinOmegaTime, cosOmegaTime, 0.0);
   rotateEcefToEci.setRow (2, 0.0, 0.0, 1.0);

   rotateEcefToEci.rotateTransposeVector (aPositionEcef, aPositionEci);
   rotateEcefToEci.rotateTransposeVector (aVelocityEcef, aVelocityEci);
   omegaEarthVector.cross (aPositionEci, omegaCrossPositionEci);
   aVelocityEci.add (omegaCrossPositionEci, aVelocityEci);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Eci to Ecef
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Conversions <T>::eciStatesToEcef (
      const double aTime,
      const Eci aPositionEci,
      const Eci aVelocityEci,
      Ecef & aPositionEcef,
      Ecef & aVelocityEcef)
{
   Eci omegaCrossPositionEci;
   Vec3<double> omegaEarthVector (0.0, 0.0, OMEGA_EARTH);
   Matrix <double> rotateEciToEcef;

   double omegaTime = OMEGA_EARTH * aTime;
   double sinOmegaTime = sin (omegaTime);
   double cosOmegaTime = cos (omegaTime);

   //Calculating Ecef to Eci DCM

   rotateEciToEcef.setRow (0,  cosOmegaTime, sinOmegaTime, 0.0);
   rotateEciToEcef.setRow (1, -sinOmegaTime, cosOmegaTime, 0.0);
   rotateEciToEcef.setRow (2, 0.0, 0.0, 1.0);

   rotateEciToEcef.rotateTransposeVector (aPositionEci, aPositionEcef);
   omegaEarthVector.cross (aPositionEci, omegaCrossPositionEci);
   aVelocityEci.subtract (omegaCrossPositionEci, omegaCrossPositionEci);
   rotateEciToEcef.rotateTransposeVector (omegaCrossPositionEci, aVelocityEcef);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Ecef to Eci DCM
////////////////////////////////////////////////////////////////////////////////

template <class T>
Matrix<T> Conversions <T>::ecefToEciDcm (const double aTime)
{
   double omegaTime = OMEGA_EARTH * aTime;
   double sinOmegaTime = sin (omegaTime);
   double cosOmegaTime = cos (omegaTime);
   Matrix <double> rotateEcefToEci;

   //Calculating Ecef to Eci DCM

   rotateEcefToEci.setRow (0, cosOmegaTime, -sinOmegaTime, 0.0);
   rotateEcefToEci.setRow (1, sinOmegaTime, cosOmegaTime, 0.0);
   rotateEcefToEci.setRow (2, 0.0, 0.0, 1.0);

   return rotateEcefToEci;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ~Conversions (Deconstructor)
////////////////////////////////////////////////////////////////////////////////

template <class T>
Conversions <T>::~Conversions (void)
{
}

} // namespace

