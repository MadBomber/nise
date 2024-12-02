////////////////////////////////////////////////////////////////////////////////
//
// Filename:         EulerMatrix.hpp
//
// Classification:   UNCLASSIFIED
//
// Unit Name:        Utilities
//
// System Name:      Simulation
//
// Description:      This file contains the class definition of EulerMatrix.
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

#ifndef _EULERMATRIX_HPP
#define _EULERMATRIX_HPP

#include "ISEExport.h"
#include "Matrix.hpp"
#include "EulerAngles.hpp"

namespace SamsonMath {

///Euler matrix class.

class ISE_Export EulerMatrix : public Matrix<double>
{
    public:

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    EulerMatrix
/// Description:  This constructor initializes the matrix from the arguments.
//  Inputs:       aR0 - First row
//                aR1 - Second row
//                aR2 - Third row
//  Outputs:      None
////////////////////////////////////////////////////////////////////////////////

    EulerMatrix (const EulerAngles aR0, const EulerAngles aR1, const EulerAngles aR2);

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    EulerMatrix
/// Description:  This constructor simply exists to initalize the arguments to
///               zero.
//  Inputs:       None
//  Outputs:      None
////////////////////////////////////////////////////////////////////////////////

    EulerMatrix ();

////////////////////////////////////////////////////////////////////////////////
//  Procedure:    ~EulerMatrix
/// Description:  This is the destructor of the class.
//  Inputs:       None
//  Outputs:      None
////////////////////////////////////////////////////////////////////////////////

   ~EulerMatrix ();
};

} // namespace

#endif


