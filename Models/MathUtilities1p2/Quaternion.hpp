////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Quaternion.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Quaternion.
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

#ifndef _QUATERNION_HPP
#define _QUATERNION_HPP

#include <math.h>
#include "Constants.hpp"

namespace SamsonMath {

template<class T>
class Quaternion
{
   private:

      T mQ0;
      T mQ1;
      T mQ2;
      T mQ3;

   public:

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    Quaternion
/// Description:  This constructor initializaes the initial arguments of the
///               quaternion function.
//  Inputs:       aQ0
//                aQ1
//                aQ2
//                aQ3
//  Outputs:      Initializes aQ0, aQ1, aQ2, and aQ3 to zero.
////////////////////////////////////////////////////////////////////////////////

   Quaternion (const T aQ0 = 0.0, const T aQ1 = 0.0, const T aQ2 = 0.0, const T aQ3 = 0.0);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operators==
/// Description:  This function compares two quaternions to see if they are
///               equal by overloading the == operator.
//  Inputs:       aQuat1
//  Returns:      true or false
////////////////////////////////////////////////////////////////////////////////

      bool operator== (const Quaternion & aQuat1);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator!=
/// Description:  This function compares two quaternions to see if they are NOT
///               equal by overloading the != operator.
//  Inputs:       aQuat1
//  Returns:      true or false
////////////////////////////////////////////////////////////////////////////////

      bool operator!= (const Quaternion & aQuat1);

////////////////////////////////////////////////////////////////////////////////
// Procedure:     operator+
/// Description:  This function adds two quaternions by overloading the + operator.
//  Inputs:       aQuat1
//  Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as:<br>
/// <b> answer = A + B; </b><br>
/// It inputs a reference and outputs a value, so it is the slower method of the two addition functions.
/// Although it is slower, the code is much more intuitive.
///

      const Quaternion<T> operator+ (const Quaternion & aQuat1);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    quaternionAdd
/// Description:  This function adds two quaternions by creating a new function.
//  Inputs:       aQuat1
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b> A.quaternionAdd (B,answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not
/// as intuitive.  That is why the overloaded operator is given as another option.
///

      void add (const Quaternion & aQuat1, Quaternion & aQResult);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator-
/// Description:  This function subtracts one quaternion from the other by
///               overloading the - operator.
//  Inputs:       aQuat2
//  Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as:<br>
/// <b> answer = A - B; </b><br>
/// It inputs a reference and outputs a value, so it is the slower method of the two subtraction functions.
/// Although it is slower, the code is much more intuitive.
///

      const Quaternion<T> operator- (const Quaternion & aQuat2);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    quaternionSubtract
/// Description:  This function subtracts one quaternion from the other by
///               creating a new function.
//  Inputs:       aQuat1
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b> A.quaternionSubtract (B,answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
/// That is why the overloaded operator is given as another option.
///

      void subtract (const Quaternion & aQuat1, Quaternion & aQResult);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator*
/// Description:  This multiplies an quaternion by a scalar by overloading the
///               * operator.
//  Inputs:       aScale
//  Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as:<br>
/// <b> answer = A * Scaler; </b><br>
/// It inputs a reference and outputs a value, so it is the slower method of the two
/// multiplication functions.  Although it is slower, the code is much more intuitive.
///

      const Quaternion<T> operator* (const T & aScale);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    quaternionScale
/// Description:  This multiplies a quaternion by a scalar by creating a new
///               function.
//  Inputs:       aScale
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b>A.quaternionScale (Scaler,answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
/// That is why the overloaded operator is given as another option.
///

      void quaternionScale (const T & aScale, Quaternion & aQResult);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator/
/// Description:  This divides an quaternion by a scalar by overloading the /
///               operator.
//  Inputs:       aScale
//  Returns:      Quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as:<br>
/// <b> answer = A / Scaler; </b><br>
/// It inputs a reference and outputs a value, so it is the slower method of the two division functions
/// Although it is slower, the code is much more intuitive.
///

      const Quaternion<T> operator/ (const T & aScale);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    quaternionDivideScale
/// Description:  This divides an quaternion by a scalar by creating a new function.
//  Inputs:       aScale
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b> A.quaternionDivideScale (Scaler,answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not as
/// intuitive.  That is why the overloaded operator is given as another option.
///

      void quaternionDivideScale (const T & aScale, Quaternion & aQResult);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    multiply
/// Description:  This multipiles two quaternions together resulting in another
///               quaternion.
//  Inputs:       aQuat1
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

      void multiply (const Quaternion & aQuat1, Quaternion & aQResult);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator!
/// Description:  This normalizes a quaternion by overloading the ! operator.
//  Inputs:       none
//  Returns:      Normalized quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as: <br>
/// <b> answer = ! A </b><br>
/// It has a voide input and outputs a value, so it is the slower method of the two inversion functions.  Although it is
/// slower, the code is much more intuitive.
///

      const Quaternion<T> operator! (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    normalize
/// Description:  This normalizes a quaternion by creating a new function.
//  Inputs:       None
//  Outputs:      Normalized quaternion
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b> A.quaternionNormalize (answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
///

      Quaternion<T> normalize (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator~
/// Description:  This inverses a quaternion by overloading the ~ operator.
//  Inputs:       None
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// This overloaded operator allows for the code to be written as:<br>
/// <b> answer = ~ A; </b><br>
/// It has a void input and outputs a value, so it is the slower method of the two inversion functions.
/// Although it is slower, the code is much more intuitive.
///

      const Quaternion<T> operator~ (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    inverse
/// Description:  This inverses a quaternion as a function call.
//  Inputs:       None
//  Outputs:      aQResult
////////////////////////////////////////////////////////////////////////////////

///
/// Creating a new function allows for the code to be written as:<br>
/// <b> A.quaternionInverse (answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  However, the code is more complicated and not as intuitive.
/// That is why the overloaded operator is given as another option.
///

      Quaternion<T> inverse (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    magnitude
/// Description:  This finds the magnitude of a quaternion.
//  Inputs:       aInputQuaternion
//  Outputs:      Magnitude
////////////////////////////////////////////////////////////////////////////////

      T magnitude (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getQ0
/// Description:  This function gets the q0 argument.
//  Inputs:       none
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      T getQ0 (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setQ0
/// Description:  This function sets the q0 argument.
//  Inputs:       aX
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      void setQ0 (const T aX);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getQ1
/// Description:  This function gets the q1 argument.
//  Inputs:       none
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      T getQ1 (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setQ1
/// Description:  This function sets the q1 argument.
//  Inputs:       aY
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      void setQ1 (const T aY);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getQ2
/// Description:  This function gets the q2 argument.
//  Inputs:       none
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      T getQ2 (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setQ2
/// Description:  This function sets the q2 argument.
//  Inputs:       aZ
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      void setQ2 (const T aZ);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getQ3
/// Description:  This function gets the q3 argument.
//  Inputs:       none
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      T getQ3 (void) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setQ3
/// Description:  This function sets the q3 argument.
//  Inputs:       aZ
//  Outputs:      none
////////////////////////////////////////////////////////////////////////////////

      void setQ3 (const T aZ);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:  Destructor
/// Description:  This is the destructor for the Quaternion class.
////////////////////////////////////////////////////////////////////////////////

      ~Quaternion ();
};

};  // namespace

#include "Quaternion.ipp"
#endif
