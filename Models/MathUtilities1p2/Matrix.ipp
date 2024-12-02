////////////////////////////////////////////////////////////////////////////////
//
// Filename:         Matrix.ipp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      MEADS Simulation
//
// Description:      This file contains the class definition of matrix.
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

namespace SamsonMath {

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Matrix (Constructor)
////////////////////////////////////////////////////////////////////////////////

template<class T>
Matrix<T>::Matrix (const Vec3 <T> aR0, const Vec3 <T> aR1, const Vec3 <T> aR2)
{
   mMatrix[0] = aR0;
   mMatrix[1] = aR1;
   mMatrix[2] = aR2;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  Matrix
////////////////////////////////////////////////////////////////////////////////

template<class T>
Matrix<T>:: Matrix (void)
{
   mMatrix[0] = Vec3<T> (0.0, 0.0, 0.0);
   mMatrix[1] = Vec3<T> (0.0, 0.0, 0.0);
   mMatrix[2] = Vec3<T> (0.0, 0.0, 0.0);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator*
////////////////////////////////////////////////////////////////////////////////

template <class T>
Matrix<T> Matrix<T>::operator* (Matrix<T> & aRhs)
{
   return Matrix<T> (setRow (0, Vec3<T> (getRow (0).getX () * aRhs.getRow (0).getX ()
                                       + getRow (0).getY () * aRhs.getRow (1).getX ()
                                       + getRow (0).getZ () * aRhs.getRow (2).getX (),
                                         getRow (0).getX () * aRhs.getRow (0).getY ()
                                       + getRow (0).getY () * aRhs.getRow (1).getY ()
                                       + getRow (0).getZ () * aRhs.getRow (2).getY (),
                                         getRow (0).getX () * aRhs.getRow (0).getZ ()
                                       + getRow (0).getY () * aRhs.getRow (1).getZ ()
                                       + getRow (0).getZ () * aRhs.getRow (2).getZ ())),
                     setRow (1, Vec3<T> (getRow (1).getX () * aRhs.getRow (0).getX ()
                                       + getRow (1).getY () * aRhs.getRow (1).getX ()
                                       + getRow (1).getZ () * aRhs.getRow (2).getX (),
                                         getRow (1).getX () * aRhs.getRow (0).getY ()
                                       + getRow (1).getY () * aRhs.getRow (1).getY ()
                                       + getRow (1).getZ () * aRhs.getRow (2).getY (),
                                         getRow (1).getX () * aRhs.getRow (0).getZ ()
                                       + getRow (1).getY () * aRhs.getRow (1).getZ ()
                                       + getRow (1).getZ () * aRhs.getRow (2).getZ ())),
                     setRow (2, Vec3<T> (getRow (2).getX () * aRhs.getRow (0).getX ()
                                       + getRow (2).getY () * aRhs.getRow (1).getX ()
                                       + getRow (2).getZ () * aRhs.getRow (2).getX (),
                                         getRow (2).getX () * aRhs.getRow (0).getY ()
                                       + getRow (2).getY () * aRhs.getRow (1).getY ()
                                       + getRow (2).getZ () * aRhs.getRow (2).getY (),
                                         getRow (2).getX () * aRhs.getRow (0).getZ ()
                                       + getRow (2).getY () * aRhs.getRow (1).getZ ()
                                       + getRow (2).getZ () * aRhs.getRow (2).getZ ())));
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  multiply
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Matrix<T>::multiply (const Matrix<T> & aRhs, Matrix<T> & aAnswer)
{
        aAnswer.setRow (0, Vec3<T> (getRow (0).getX () * aRhs.getRow (0).getX ()
                                  + getRow (0).getY () * aRhs.getRow (1).getX ()
                                  + getRow (0).getZ () * aRhs.getRow (2).getX (),
                                    getRow (0).getX () * aRhs.getRow (0).getY ()
                                  + getRow (0).getY () * aRhs.getRow (1).getY ()
                                  + getRow (0).getZ () * aRhs.getRow (2).getY (),
                                    getRow (0).getX () * aRhs.getRow (0).getZ ()
                                  + getRow (0).getY () * aRhs.getRow (1).getZ ()
                                  + getRow (0).getZ () * aRhs.getRow (2).getZ ()));

        aAnswer.setRow (1, Vec3<T> (getRow (1).getX () * aRhs.getRow (0).getX ()
                                  + getRow (1).getY () * aRhs.getRow (1).getX ()
                                  + getRow (1).getZ () * aRhs.getRow (2).getX (),
                                    getRow (1).getX () * aRhs.getRow (0).getY ()
                                  + getRow (1).getY () * aRhs.getRow (1).getY ()
                                  + getRow (1).getZ () * aRhs.getRow (2).getY (),
                                    getRow (1).getX () * aRhs.getRow (0).getZ ()
                                  + getRow (1).getY () * aRhs.getRow (1).getZ ()
                                  + getRow (1).getZ () * aRhs.getRow (2).getZ ()));

        aAnswer.setRow (2, Vec3<T> (getRow (2).getX () * aRhs.getRow (0).getX ()
                                  + getRow (2).getY () * aRhs.getRow (1).getX ()
                                  + getRow (2).getZ () * aRhs.getRow (2).getX (),
                                    getRow (2).getX () * aRhs.getRow (0).getY ()
                                  + getRow (2).getY () * aRhs.getRow (1).getY ()
                                  + getRow (2).getZ () * aRhs.getRow (2).getY (),
                                    getRow (2).getX () * aRhs.getRow (0).getZ ()
                                  + getRow (2).getY () * aRhs.getRow (1).getZ ()
                                  + getRow (2).getZ () * aRhs.getRow (2).getZ ()));
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  operator~
////////////////////////////////////////////////////////////////////////////////

template <class T>
const Matrix<T> Matrix<T>::operator~ (void)
{
   T determinant        = 0.0;
   T oneOverDeterminant = 0.0;

   Matrix<T> answer;

   /* Calculate the matrix determinant */

   determinant =   getRow (0).getX () * getRow (1).getY () * getRow (2).getZ ()
                 - getRow (0).getX () * getRow (2).getY () * getRow (2).getY ()
                 - getRow (1).getX () * getRow (1).getX () * getRow (2).getZ ()
                 + 2.0 * getRow (1).getX () * getRow (2).getX () * getRow (2).getY ()
                 - getRow (2).getX () * getRow (2).getX () * getRow (1).getY ();

   if (determinant != 0.0)
   {
      oneOverDeterminant = 1.0 / determinant;
   }
   else
   {
      oneOverDeterminant = 0.0;
   }

   /* Calculate the inverse of the matrix using Cramer's rule */

   answer.setRow (0, Vec3<T> (
          (getRow (1).getY () * getRow (2).getZ () - getRow (2).getY () * getRow (2).getY ()) * oneOverDeterminant,
         -(getRow (1).getX () * getRow (2).getZ () - getRow (2).getX () * getRow (2).getY ()) * oneOverDeterminant,
          (getRow (1).getX () * getRow (2).getY () - getRow (1).getY () * getRow (2).getX ()) * oneOverDeterminant));

   answer.setRow (1, Vec3<T> (
          answer.getRow (0).getY (),
          (getRow (0).getX () * getRow (2).getZ () - getRow (2).getX () * getRow (2).getX ()) * oneOverDeterminant,
         -(getRow (0).getX () * getRow (2).getY () - getRow (1).getX () * getRow (2).getX ()) * oneOverDeterminant));

   answer.setRow (2, Vec3<T> (
          answer.getRow (0).getZ (),
          answer.getRow (1).getZ (),
         (getRow (0).getX () * getRow (1).getY () - getRow (1).getX () * getRow (1).getX ()) * oneOverDeterminant));

  return answer;
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  inverse
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Matrix<T>::inverse (Matrix & aAnswer)
{
   T determinant, oneOverDeterminant = 0.0;

   /* Calculate the matrix determinant */

   determinant =   getRow (0).getX () * getRow (1).getY () * getRow (2).getZ ()
                 - getRow (0).getX () * getRow (2).getY () * getRow (2).getY ()
                 - getRow (1).getX () * getRow (1).getX () * getRow (2).getZ ()
                 + 2.0 * getRow (1).getX () * getRow (2).getX () * getRow (2).getY ()
                 - getRow (2).getX () * getRow (2).getX () * getRow (1).getY ();

   if (determinant != 0.0)
   {
      oneOverDeterminant = 1.0 / determinant;
   }
   else
   {
      oneOverDeterminant = 0.0;
   }

   /* Calculate the inverse of the matrix using Cramer's rule */

   aAnswer.setRow (0, Vec3<T> (
          (getRow (1).getY () * getRow (2).getZ () - getRow (2).getY () * getRow (2).getY ()) * oneOverDeterminant,
         -(getRow (1).getX () * getRow (2).getZ () - getRow (2).getX () * getRow (2).getY ()) * oneOverDeterminant,
          (getRow (1).getX () * getRow (2).getY () - getRow (1).getY () * getRow (2).getX ()) * oneOverDeterminant));

   aAnswer.setRow (1, Vec3<T> (
          aAnswer.getRow (0).getY (),
          (getRow (0).getX () * getRow (2).getZ () - getRow (2).getX () * getRow (2).getX ()) * oneOverDeterminant,
         -(getRow (0).getX () * getRow (2).getY () - getRow (1).getX () * getRow (2).getX ()) * oneOverDeterminant));

   aAnswer.setRow (2, Vec3<T> (
         aAnswer.getRow (0).getZ (),
         aAnswer.getRow (1).getZ (),
         (getRow (0).getX () * getRow (1).getY () - getRow (1).getX () * getRow (1).getX ()) * oneOverDeterminant));

}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  IDENTITY
////////////////////////////////////////////////////////////////////////////////

// TODO make this work like  A = B.setToIdentity()  ???????????
template <class T>
void Matrix<T>::setToIdentity (void)
{
   this->setRow (0, 1.0, 0.0, 0.0);
   this->setRow (1, 0.0, 1.0, 0.0);
   this->setRow (2, 0.0, 0.0, 1.0);
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  getRow
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3 <T> Matrix<T>::getRow (int aRow) const
{
   return mMatrix[aRow];
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setRow
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3<T> Matrix<T>::setRow (const int aRow, const Vec3 <T> & aData)
{
   mMatrix[aRow] = aData;

   return mMatrix[aRow];
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  setRow overloaded to allow direct initialization
////////////////////////////////////////////////////////////////////////////////

template <class T>
Vec3 <T> Matrix<T>::setRow (const int aRow, const double aX, const double aY, const double aZ)
{
   Vec3 <double> column (aX, aY, aZ);
   mMatrix[aRow] = column;

   return mMatrix[aRow];
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  rotateVector
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Matrix<T>::rotateVector (const Vec3 <T> & aLhs, Vec3 <T> & aAnswer)
{
   aAnswer.setX (aLhs.getX () * mMatrix[0].getX ()
               + aLhs.getY () * mMatrix[0].getY ()
               + aLhs.getZ () * mMatrix[0].getZ ());

   aAnswer.setY (aLhs.getX () * mMatrix[1].getX ()
               + aLhs.getY () * mMatrix[1].getY ()
               + aLhs.getZ () * mMatrix[1].getZ ());

   aAnswer.setZ (aLhs.getX () * mMatrix[2].getX ()
               + aLhs.getY () * mMatrix[2].getY ()
               + aLhs.getZ () * mMatrix[2].getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  rotateTransposeVector
////////////////////////////////////////////////////////////////////////////////

template <class T>
void Matrix<T>::rotateTransposeVector (const Vec3 <T> & aLhs, Vec3 <T> & aAnswer)
{
   aAnswer.setX (aLhs.getX () * mMatrix[0].getX ()
               + aLhs.getY () * mMatrix[1].getX ()
               + aLhs.getZ () * mMatrix[2].getX ());

   aAnswer.setY (aLhs.getX () * mMatrix[0].getY ()
               + aLhs.getY () * mMatrix[1].getY ()
               + aLhs.getZ () * mMatrix[2].getY ());

   aAnswer.setZ (aLhs.getX () * mMatrix[0].getZ ()
               + aLhs.getY () * mMatrix[1].getZ ()
               + aLhs.getZ () * mMatrix[2].getZ ());
}

////////////////////////////////////////////////////////////////////////////////
// Procedure:  ~Matrix (Destructor)
////////////////////////////////////////////////////////////////////////////////

/// This is the destructor for the Matrix class.

template <class T>
Matrix<T>::~Matrix (void)
{
}

} // namespace
