////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Matrix.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of Matrix.
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

#ifndef _MATRIX_HPP
#define _MATRIX_HPP

#include "Vec3.hpp"

namespace SamsonMath {

/// Matrix class.

/// Instead of creating a 3x3 matrix, this class is a one-dimensional array with three Vec3.
/// Vec31 (X, Y, Z)
/// Vec32 (X, Y, Z)
/// Vec33 (X, Y, Z)

template<class T>
class Matrix
{
   private:

    Vec3 <T> mMatrix[3];

    //typedef Vec3 <T> Row;
	//Row[3] mMatrix;

   public:

////////////////////////////////////////////////////////////////////////////////
//  Procdure:     Matrix
/// Description:  This constructor initializes the matrix from the arguments.
////////////////////////////////////////////////////////////////////////////////

       Matrix (const Vec3 <T> aR0, const Vec3 <T> aR1, const Vec3 <T> aR2);

////////////////////////////////////////////////////////////////////////////////
//  Procdure:     Matrix
/// Description:  This constructor simply exists to initalize the arguments to zero.
////////////////////////////////////////////////////////////////////////////////

      Matrix ();

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator*
/// Description:  This multiplies two matrices together by overloading the
///               * operator.
//  Inputs:       aRhs
////////////////////////////////////////////////////////////////////////////////

/// This overloaded operator allows for the code to be written as:<br>
/// <b>  answer = A * B; </b><br>
/// It inputs a reference and outputs a value, so it is the slower method
/// of the two multiplication functions.  Although it is slower, the code
/// is much more intuitive.

      Matrix <T> operator* (Matrix<T> & aRhs);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    multiply
/// Description:  This multiplies two matrices together by creating a new function.
//  Inputs:       aRhs
//  Output:       aAnswer
////////////////////////////////////////////////////////////////////////////////

/// Creating a new function allows for the code to be written as:<br>
/// <br>  A.multiply (B,answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  The code is more complicated and not as intuitive.
/// That is why the overloaded operator is given as another option.

      void multiply (const Matrix & aRhs, Matrix & aAnswer);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    operator~
/// Description:  This finds the inverse of a matrix by overloading the
///               ~ operator.
//  Inputs:       None
//  Output:       Inverted matrix
////////////////////////////////////////////////////////////////////////////////

/// This overloaded operator allows for the code to be written as:<br>
/// <b>  answer = ~ A; </b><br>
/// It has a void input and outputs a value, so it is the slower method of the two inversion functions.
/// Although it is slower, the code is much more intuitive.

      const Matrix <T> operator~ (void);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    inverse
/// Description:  This finds the inverse of a matrix by creating a new function.
//  Inputs:       None
//  Output:       Inverted matrix
////////////////////////////////////////////////////////////////////////////////

/// Creating a new function allows for the code to be written as:<br>
/// <b>  A.inverse (answer); </b><br>
/// It inputs a reference and has a void output.  However, the output is then referenced by the code,
/// so this method allows for much faster computation.  The code is more complicated and not as intuitive.
/// That is why the overloaded operator is given as another option.

      void inverse (Matrix & aAnswer);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    getRow
/// Description:  This function gets an entire row of the matrix.
//  Inputs:       aRow
//  Output:       Vec3
////////////////////////////////////////////////////////////////////////////////

      Vec3 <T> getRow (const int aRow) const;

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setRow
/// Description:  This function sets an entire row of the matrix.
//  Inputs:       aRow
//                aData
//  Output:       Vec3
////////////////////////////////////////////////////////////////////////////////

      Vec3 <T> setRow (const int aRow, const Vec3 <T> & aData);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setRow
/// Description:  This function sets an entire row of the matrix.
//  Inputs:       aRow
//                aX
//                aY
//                aZ
//  Output:       Vec3
////////////////////////////////////////////////////////////////////////////////

      Vec3 <T> setRow (const int aRow, const double aX, const double aY,
                       const double aZ);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    rotateVector
/// Description:  This function rotates a Vec3 vector or a derivative of it by
///               multiplying it by a matrix.
//  Inputs:       aLhs
//  Output:       aAnswer
////////////////////////////////////////////////////////////////////////////////

      void rotateVector (const Vec3 <T> & aLhs, Vec3 <T> & aAnswer);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    rotateTransposeVector
/// Description:  This function rotates and transposes a Vec3 vector or a
///               derivative of it by multiplying it by a matrix.
//  Inputs:       aLhs
//  Output:       aAnswer
////////////////////////////////////////////////////////////////////////////////

      void rotateTransposeVector (const Vec3 <T> & aLhs, Vec3 <T> & aAnswer);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    rotateTransposeVector
/// Description:  This function also rotates and transposes a Vec3 vector or a
///               derivative of it by multiplying it by a matrix.
//  Inputs:       aRhs
//  Returns:      Resultant vector
////////////////////////////////////////////////////////////////////////////////

      //TODO const Vec3 <T> rotateTransposeVector (const Vec3 <T> & aRhs);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ~Matrix
/// Description:  This is the destructor for the Matrix class.
////////////////////////////////////////////////////////////////////////////////

      virtual ~Matrix ();

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    setToIdentity
/// Description:  This fuction set the matrix to the Identity matrix.
////////////////////////////////////////////////////////////////////////////////

    void setToIdentity (void);
};

} // namespace


#include "Matrix.ipp"
#endif

