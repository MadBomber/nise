// v50207, by Ray Sells, DESE Research, Inc.
#ifndef QUAT_H
#define QUAT_H

#include <iostream>
#include <cmath>
using namespace std;

#include "mat.h"

namespace tframes {

class Quat {
  public:
    double s, x, y, z;
    Quat( double s, double x, double y, double z);
    Quat();
    Quat operator()( double, double, double, double);
    double &operator[]( int i);
    Quat normalize();
    Mat getDCM();
  private:
};

ostream &operator<<( ostream &stream, Quat q);

} // end namespace tframes

#endif

