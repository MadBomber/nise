////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Vec3.ipp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      MEADS Simulation
//
// Description:      This file contains the class definition of the Vec3 template.
//                   Limitations are used by Lla, Ned, Ecef, Eci.
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
//  20051111   HLB   Original Release
//
////////////////////////////////////////////////////////////////////////////////

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Vec3 Constructors
/////////////////////////////////////////////////////////////////////////////////
using namespace std;
template <class T>
Vec3<T>::Vec3 (T aX, T aY, T aZ) : mX (aX), mY (aY), mZ (aZ)
{
}

template<class T>
Vec3<T>::Vec3 (const Vec3<T> & aVec)
{
   setX (aVec.getX ());
   setY (aVec.getY ());
   setZ (aVec.getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: Vec3 Destructors
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T>::~Vec3 (void)
{
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator<< (Friend)
////////////////////////////////////////////////////////////////////////////////

template <class T>
std::ostream& operator<< (std::ostream& aOutput, const Vec3<T> & aVec)
{
   // prints in the form: <x, y, z>

//hlb   aOutput << "<" << aVec.mX << ", " << aVec.mY << ", " << aVec.mZ << ">";
   aOutput << aVec.mX << " " << aVec.mY << " " << aVec.mZ;;


   return (aOutput);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator* (Friend)
////////////////////////////////////////////////////////////////////////////////

///This friend function allows scaler multiplication in the form: Vec3 = Scaler * Vec3.

template <class T>
Vec3<T> operator* (const T aLhs, const Vec3<T> & aVec)
{
   return Vec3<T> (aVec.getX () * aLhs, aVec.getY () * aLhs, aVec.getZ () * aLhs);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getX
////////////////////////////////////////////////////////////////////////////////

template <class T>
T Vec3<T>::getX (void) const
{
   return mX;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getY
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline T Vec3<T>::getY (void) const
{
   return mY;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getZ
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline T Vec3<T>::getZ (void) const
{
   return mZ;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setX
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline void Vec3<T>::setX (const T aX)
{
   mX = aX;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setY
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline void Vec3<T>::setY (const T aY)
{
   mY = aY;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setZ
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline void Vec3<T>::setZ (const T aZ)
{
   mZ = aZ;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setXYZ
////////////////////////////////////////////////////////////////////////////////

template <class T>
inline void Vec3<T>::setXYZ (const T aX, const T aY, const T aZ)
{
   mX = aX;
   mY = aY;
   mZ = aZ;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator==
////////////////////////////////////////////////////////////////////////////////

template <class T>
bool Vec3<T>::operator== (const Vec3 & aRhs) const
{
   if (aRhs.mX != mX || aRhs.mY != mY  || aRhs.mZ != mZ)
   {
      return false;
   }
   else
   {
      return true;
   }
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator!
////////////////////////////////////////////////////////////////////////////////

template <class T>
bool Vec3<T>::operator!= (const Vec3 & aRhs) const
{
   if (aRhs.mX != mX || aRhs.mY != mY  || aRhs.mZ != mZ)
   {
      return true;
   }
   else
   {
      return false;
   }
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator+=
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T> Vec3<T>::operator+= (const Vec3<T> & aRhs)
{
   *this = *this + aRhs;
   return (*this);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator-=
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T> Vec3<T>::operator-= (const Vec3<T> & aRhs)
{
   *this = *this - aRhs;
   return (*this);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator+
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Vec3<T> Vec3<T>::operator+ (const Vec3<T> & aRhs) const
{
  return Vec3<T> (mX + aRhs.mX, mY + aRhs.mY, mZ + aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator-
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Vec3<T> Vec3<T>::operator- (const Vec3<T> & aRhs) const
{
   return Vec3<T> (mX - aRhs.mX, mY - aRhs.mY, mZ - aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator*
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Vec3<T> Vec3<T>::operator* (const T & aScale) const
{
   return Vec3<T> (mX * aScale, mY * aScale, mZ * aScale);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator/
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Vec3<T> Vec3<T>::operator/ (const T & aScale) const
{
   if (aScale > EPSILON)
   {
      return Vec3<T>(mX / aScale, mY / aScale, mZ / aScale);
   }
   else
   {
      std::cerr << "division by 0 not allowed --> Vec3::/" << endl;
      return 0.0;
   }
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator^
////////////////////////////////////////////////////////////////////////////////

template <class T>
const T Vec3<T>::operator^ (const Vec3 & aRhs) const
{
   return T (mX * aRhs.mX + mY * aRhs.mY + mZ * aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator%
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T> Vec3<T>::operator% (const Vec3<T> & aRhs) const
{
   return Vec3<T> (aRhs.mZ * mY - aRhs.mY * mZ,
                   aRhs.mX * mZ - aRhs.mZ * mX,
                   aRhs.mY * mX - aRhs.mX * mY);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator!
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Vec3<T> Vec3<T>::operator! (void) const
{
   T mag;

   magnitude (mag);

   if (mag > EPSILON)
   {
      return (*this / mag);
   }
   else
   {
      return *this;
   }
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: add (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::add (const Vec3<T> & aRhs, Vec3<T> & aAnswer) const
{
   aAnswer.mX = aRhs.mX + mX;
   aAnswer.mY = aRhs.mY + mY;
   aAnswer.mZ = aRhs.mZ + mZ;
}

template <class T>
Vec3<T> Vec3<T>::add (const Vec3<T> & aRhs) const
{
   return Vec3<T> (mX + aRhs.mX, mY + aRhs.mY, mZ + aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: subtract (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::subtract (const Vec3<T> & aRhs, Vec3<T> & aAnswer) const
{
   aAnswer.mX = mX - aRhs.mX;
   aAnswer.mY = mY - aRhs.mY;
   aAnswer.mZ = mZ - aRhs.mZ;
}

template <class T>
Vec3<T> Vec3<T>::subtract (const Vec3<T> & aRhs) const
{
   return Vec3<T> (mX - aRhs.mX, mY - aRhs.mY, mZ - aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: multiply (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::multiply (const T & aScale, Vec3<T> & aAnswer) const
{
   aAnswer.mX = mX * aScale;
   aAnswer.mY = mY * aScale;
   aAnswer.mZ = mZ * aScale;
}

template < class T >
Vec3<T> Vec3<T>::multiply (const T & aScale) const
{
   return Vec3<T> (mX * aScale, mY * aScale, mZ * aScale);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: divide (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::divide (const T & aScale, Vec3<T> & aAnswer) const
{
   if (aScale > EPSILON)
   {
        aAnswer.mX = mX / aScale;
        aAnswer.mY = mY / aScale;
        aAnswer.mZ = mZ / aScale;
   }
   else
   {
      std::cerr << "division by 0 not allowed --> Vec3::divide" << endl;

      aAnswer = 0.0;
   }
}

template <class T>
Vec3<T> Vec3<T>::divide (const T & aScale) const
{
   if (aScale > EPSILON)
   {
      return Vec3<T> (mX / aScale, mY / aScale, mZ / aScale);
   }
   else
   {
      std::cerr << "division by 0 not allowed --> Vec3::divide" << endl;
      return Vec3<T> (0.0, 0.0, 0.0);
   }
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: dot (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::dot (const Vec3<T> & aRhs, T & aAnswer) const
{
   aAnswer = mX * aRhs.mX + mY * aRhs.mY + mZ * aRhs.mZ;
}

template <class T>
T Vec3<T>::dot (const Vec3<T> & aRhs) const
{
  return T (mX * aRhs.mX + mY * aRhs.mY + mZ * aRhs.mZ);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: cross (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::cross (const Vec3<T> & aRhs, Vec3<T> & aVectorResult) const
{
   aVectorResult.mX = aRhs.mZ * mY - aRhs.mY * mZ ;
   aVectorResult.mY = aRhs.mX * mZ - aRhs.mZ * mX ;
   aVectorResult.mZ = aRhs.mY * mX - aRhs.mX * mY ;
}

template <class T>
Vec3<T>  Vec3<T>::cross (const Vec3<T> & aRhs) const
{
  return Vec3<T> (aRhs.mZ * mY - aRhs.mY * mZ,
                  aRhs.mX * mZ - aRhs.mZ * mX,
                  aRhs.mY * mX - aRhs.mX * mY);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: magnitude (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::magnitude (T & aMagnitude) const
{
   aMagnitude = sqrt (getX () * getX () + getY () * getY () + getZ () * getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure: unitize (Fast Operator)
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Vec3<T>::unitize (Vec3<T> & aVectorResult)
{
   T mag;

   magnitude (mag);

   if (mag > EPSILON)
   {
      aVectorResult = *this / mag;
   }
   else
   {
      aVectorResult = *this;
   }
}

} // namespace

