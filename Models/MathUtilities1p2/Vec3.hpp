////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Vec3.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
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
//  20051114   HLB   Originial Release
//
////////////////////////////////////////////////////////////////////////////////

#ifndef _VEC3_HPP
#define _VEC3_HPP

#include "ISEExport.h"
#include <math.h>
#include <iostream>

// include headers that implement a archive in simple text format
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/nvp.hpp>

#include "Constants.hpp"

namespace SamsonMath {

// A trick to get the compiler to recognice that << is actually a template function
// The snag happens when the compiler sees the friend lines way up in the class definition proper. 
// At that moment it does not yet know the friend functions are themselves templates; it assumes they are non-templates
//
// The trick with the <> by itself used to work in gcc 3.x  but not 4.x
//
// The solution can be found at  http://geneura.ugr.es/~jmerelo/c++-faq/containers-and-templates.html

template<class T> class Vec3;
template<class T> std::ostream& operator<< (std::ostream& aOutput, const Vec3<T>& aVec);


//.................................................
template<class T>
class ISE_Export Vec3
{
   public:
 
      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    Vec3
      /// Description:  This constructor defaults the values to 0.0
      //  Inputs:       aX
      //                aY
      //                aZ
      // Outputs:       Initializes aQ, aY, aZ to zero.
      ////////////////////////////////////////////////////////////////////////////////

      Vec3 (const T aX = 0.0, T aY = 0.0, T aZ = 0.0);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    Vec3
      /// Description:  The copy constructor copies values from another Vec3
      //  Inputs:       aVec
      //  Output:       Vec3
      ////////////////////////////////////////////////////////////////////////////////

      Vec3 (const Vec3<T> & aVec);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    ~Vec3
      /// Description:  This is the destructor for the Vec3 class.
      ////////////////////////////////////////////////////////////////////////////////

      virtual ~Vec3 ();

      ////////////////////////////////////////////////////////////////////////////////
      // Procedure:    <<
      // Description:  Overloaded I/O Operators
      // Inputs:       aVec
      // Output:       aOutput
      ////////////////////////////////////////////////////////////////////////////////

      friend std::ostream& operator<< <>(std::ostream& aOutput, const Vec3<T>& aVec);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    getX
      /// Description:  This function gets the X argument.
      //  Inputs:       none
      //  Outputs:      none
      ////////////////////////////////////////////////////////////////////////////////

      T getX (void) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    getY
      /// Description:  This function gets the Y argument.
      //  Inputs:       none
      //  Outputs:      none
      ////////////////////////////////////////////////////////////////////////////////

      T getY (void) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    getZ
      /// Description:  This function gets the Z argument.
      //  Inputs:       none
      //  Outputs:      none
      ////////////////////////////////////////////////////////////////////////////////

      T getZ (void) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    setX
      /// Description:  This function sets the X argument.
      //  Inputs:       aX
      //  Output:       none
      ////////////////////////////////////////////////////////////////////////////////

      void setX (const T aX);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    setY
      /// Description:  This function sets the Y argument.
      //  Inputs:       aY
      //  Output:       none
      ////////////////////////////////////////////////////////////////////////////////

      void setY (const T aY);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    setZ
      /// Description:  This function sets the Z argument.
      //  Inputs:       aZ
      //  Output:       none
      ////////////////////////////////////////////////////////////////////////////////

      void setZ (const T aZ);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    setXYZ
      /// Description:  This function sets the XYZ argument.
      //  Inputs:       aX
      //                aY
      //                aZ
      //  Output:       none
      ////////////////////////////////////////////////////////////////////////////////

      void setXYZ (const T aX, const T aY, const T aZ);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator==
      /// Description:  This function compares two vectors to see if they are equal
      ///               by overloading the == operator.
      //  Inputs:       aRhs
      //  Returns:      true or
      //                false
      ////////////////////////////////////////////////////////////////////////////////

      bool operator== (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator!=
      /// Description:  This function compares two vectors to see if they are NOT
      ///               equal by overloading the != operator.
      //  Inputs:       aRhs
      //  Returns:      true or
      //                false
      ////////////////////////////////////////////////////////////////////////////////

      bool operator!= (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator+=
      /// Description:  This function Adds two vectors by overloading the += operator.
      //  Inputs:       aRhs
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> A += B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two addition functions.  Although it is slower, the code is much more intuitive.
      ///

      Vec3<T> operator+= (const Vec3 & aRhs);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator-=
      /// Description:  This function subtracts two vectors by overloading the -= operator.
      //  Inputs:       aRhs
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> A -= B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the two
      ///addition functions.  Although it is slower, the code is much more intuitive.
      ///

      Vec3<T> operator-= (const Vec3 & aRhs);

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator+
      /// Description:  This function adds two vectors by overloading the + operator.
      //  Inputs:       aRhs
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A + B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two addition functions.  Although it is slower, the code is much more intuitive.
      ///

      const Vec3<T> operator+ (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator-
      /// Description:  This function subtracts one vector from the other by overloading
      ///               the - operator.
      //  Inputs:       aRhs
      //  Output:       Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A - B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two subtraction functions.  Although it is slower, the code is much more intuitive.
      ///

      const Vec3<T> operator- (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator*
      /// Description:  This multiplies a vector by a scalar by overloading the
      ///               * operator.
      //  Inputs:       aScale
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A * aScaler; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two multiplication functions.  Although it is slower, the code is much more intuitive.
      ///.

      const Vec3<T> operator* (const T & aScale) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator/
      /// Description:  This divides a vector by a scalar by overloading the / operator.
      //  Inputs:       aScale
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A / aScaler; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two division functions.  Although it is slower, the code is much more intuitive.
      ///

      const Vec3<T> operator/ (const T & aScale) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator^
      /// Description:  This takes the dot product of two vectors by overloading
      ///               the ^ operator.
      //  Inputs:       aRhs
      //  Returns:      T
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A ^ B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two division functions.  Although it is slower, the code is much more intuitive.
      ///

      const T operator^ (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator%
      /// Description:  This takes the cross product of two vectors by overloading
      ///               the % operator.
      //  Inputs:       aRhs
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = A % B; </b><br>
      ///It inputs a reference and outputs a value, so it is the slower method of the
      ///two division functions.  Although it is slower, the code is much more intuitive.
      ///.

      Vec3<T> operator% (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    operator!
      /// Description:  This solves for a unit vector of the vector by overloading
      ///               the ! operator.
      //  Inputs:       none
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///This overloaded operator allows for the code to be written as:<br>
      /// <b> answer = ! A; </b><br>
      ///It has a void input and outputs a value, so it is the slower method of the
      ///two inversion functions.  Although it is slower, the code is much more intuitive.
      ///

      const Vec3<T> operator! (void) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    add (Fast Operator)
      /// Description:  This function adds two vectors but returns the answer as
      ///               a reference.
      //  Inputs:       aRhs
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.Add (B,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then referenced by the code,
      ///so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
      ///That is why the overloaded operator is given as another option.
      ///

      void add (const Vec3 & aRhs, Vec3 & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    add (Fast Operator)
      /// Description:  This function adds two vectors but returns the answer as
      ///               a reference.
      //  Inputs:       aRhs
      //  Returns:      sum
      ////////////////////////////////////////////////////////////////////////////////

      Vec3<T> add (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    subtract (Fast Operator)
      /// Description:  This function subtracts one vector from the other by
      ///               creating a new function.
      //  Inputs:       aRhs
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.Subtract (B,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then referenced by the code,
      ///so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
      ///That is why the overloaded operator is given as another option.
      ///

      void subtract (const Vec3 & aRhs, Vec3 & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    subtract (Fast Operator)
      /// Description:  This function subtracts one vector from the other by
      ///               creating a new function.
      //  Inputs:       aRhs
      //  Returns:      sum
      ////////////////////////////////////////////////////////////////////////////////

      Vec3<T> subtract (const Vec3 & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    multiply (Fast Operator)
      /// Description:  This multiplies a vector by a scalar by creating a new function.
      //  Inputs:       aScale
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.Multiply (aScaler,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then referenced by the code,
      ///so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
      ///That is why the overloaded operator is given as another option.
      ///

      void multiply (const T & aScale, Vec3 & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    multiply (Fast Operator)
      /// Description:  This multiplies a vector by a scalar by creating a new function.
      //  Inputs:       aScale
      //  Returns:      product
      ////////////////////////////////////////////////////////////////////////////////

      Vec3<T> multiply (const T & aScale) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    divide (Fast Operator)
      /// Description:  This divides a vector by a scalar by creating a new function.
      //  Inputs:       aScale
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.Divide (aScaler,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then
      ///referenced by the code, so this method allows for much faster computation.
      ///However, the code is more complicated and not as intuitive.  That is why the
      ///overloaded operator is given as another option.
      ///

      void divide (const T & aScale, Vec3 & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    divide (Fast Operator)
      /// Description:  This divides a vector by a scalar by creating a new function.
      //  Inputs:       aScale
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      Vec3<T> divide (const T & aScale) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    dot (Fast Operator)
      /// Description:  This takes the dot product of two vectors by creating a
      ///               new function.
      //  Inputs:       aRhs
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.dot (B,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then
      ///referenced by the code, so this method allows for much faster computation.
      ///However, the code is more complicated and not as intuitive.  That is why the
      ///overloaded operator is given as another option.
      ///

      void dot (const Vec3 & aRhs, T & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    dot (Fast Operator)
      /// Description:  This takes the dot product of two vectors by creating a
      ///               new function.
      //  Inputs:       aRhs
      //  Returns:      scaler product
      ////////////////////////////////////////////////////////////////////////////////

      T dot (const Vec3<T> & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    cross (Fast Operator)
      /// Description:  This takes the cross product of two vectors by creating a
      ///               new function.
      //  Inputs:       aRhs
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.cross (B,answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output is then
      ///referenced by the code, so this method allows for much faster computation.
      ///That is why the overloaded operator is given as another option.
      ///

      void cross (const Vec3 & aRhs, Vec3 & aAnswer) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    cross (Fast Operator)
      /// Description:  This takes the cross product of two vectors by creating a
      ///               new function.
      //  Inputs:       aRhs
      //  Returns:      Vec3
      ////////////////////////////////////////////////////////////////////////////////

      Vec3<T> cross (const Vec3<T> & aRhs) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    magnitude (Fast Operator)
      /// Description:  This solves for the magnitude of a vector.
      //  Inputs:       none
      //  Output:       aMagnitude
      ////////////////////////////////////////////////////////////////////////////////

      void magnitude (T & aMagnitude) const;

      ////////////////////////////////////////////////////////////////////////////////
      //  Procedure:    unitize (Fast Operator)
      /// Description:  This solves for a unit vector of the vector by creating a
      ///               new function.
      //  Inputs:       none
      //  Output:       aAnswer
      ////////////////////////////////////////////////////////////////////////////////

      ///
      ///Creating a new function allows for the code to be written as:<br>
      /// <b> A.UnitVector (answer); </b><br>
      ///It inputs a reference and has a void output.  However, the output
      ///is then referenced by the code, so this method allows for much
      ///faster computation.  However, the code is more complicated and not
      ///as intuitive.  That is why the overloaded operator is given as
      ///another option.
      ///

      void unitize (Vec3 & aAnswer);


	// Boost Serialization
	friend class boost::serialization::access;
	// When the class Archive corresponds to an output archive, the
	// & operator is defined similar to <<.  Likewise, when the class Archive
	// is a type of input archive the & operator is defined similar to >>.
	template<class Archive>
	void serialize(Archive & ar, const unsigned int)
	{
		ar & BOOST_SERIALIZATION_NVP(mX);
		ar & BOOST_SERIALIZATION_NVP(mY);
		ar & BOOST_SERIALIZATION_NVP(mZ);
	}
#if 0
	void serialize (boost::archive::polymorphic_iarchive & ar, const unsigned int )
	{
		ar & BOOST_SERIALIZATION_NVP(mX);
		ar & BOOST_SERIALIZATION_NVP(mY);
		ar & BOOST_SERIALIZATION_NVP(mZ);
	}
	void serialize (boost::archive::polymorphic_oarchive & ar, const unsigned int )
	{
		ar & BOOST_SERIALIZATION_NVP(mX);
		ar & BOOST_SERIALIZATION_NVP(mY);
		ar & BOOST_SERIALIZATION_NVP(mZ);
	}
#endif
	
   private:
      T mX;
      T mY;
      T mZ;
};

} // namespace

#include "Vec3.ipp"
#endif
