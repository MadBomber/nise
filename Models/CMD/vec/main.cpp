// v50207, by Ray Sells, DESE Research, Inc.
#include <iostream>
#include <cmath>
#include "quat.h"
using namespace std;

// these are simple demo functions used below
double threshold( double x) {
  if( fabs( x) < 1.0e-6) {
    return 0.0;
  }
  else {
    return x;
  }
}

double add1( double x) {
  return x + 1.0;
}

double rand_double( double) {
  return ( double)rand() / RAND_MAX;
}

int main() {
  //======== Basic Vector stuff
  // different constructor calls
  tframes::Vec v0, v1( 10., 20., 30.), v2, v3, v4;
  tframes::Vec v5( -1.0, -2.0, -3.0);
  tframes::Vec v6, v7, v8;

  // all elements set to 0 if not initialized
  cout << v0.x << " " << v0.y << " " << v0.z << endl;
  // << operator is overloaded for easy output
  cout << v1 << endl;

  // alternate ways to access Vec elements
  v2.x = -100.0;
  v2.y = -200.0;
  v2.z = -300.0;
  cout << v2 << endl;
  v2[0] = 100.0;
  v2[1] = 200.0;
  v2[2] = 300.0;
  cout << v2 << endl;

  // easy way to extract vec elements into other variables
  double phi, theta, psi;
  v2.extract( phi, theta, psi);
  cout << phi << " " << theta << " " << psi << endl;

  // easy way to assign (reassign) values to a Vec
  v3( -1.0, 2.0, 3.0);
  cout << v3 << endl;
  // reassign v3 and set v4 equal to it
  v4 = v3( -100.0, -200.0, -300.0);
  cout << v3 << endl;
  cout << v4 << endl;
  // NEW: alternate way to set
  v6 = 0.0;
  v7 = 1.0;
  cout << v6 << " " << v7 << endl;

  // math operator overloading
  v3 = v1 + v2;
  cout << v3 << endl;
  v4 = v2 - v1;
  cout << v4 << endl;
  // simple way to scale a vector by a scalar
  v3 = v4 * 10.0;
  cout << v3 << endl;
  v3 = v3 / 10.0;
  cout << v3 << endl;

  // |Vec| must be calculated explicitly.  A value is returned that can
  // be used and the "Vec" ".m" attribute can then be set.
  v1.m = v1.mag();
  cout << v1 << " " << v1.m << endl;

  // easy way to apply function to all elements of a Vec
  v3 = v5.apply( fabs); // use c++ fabs()
  cout << v3 << endl;
  v3 = v5.apply( add1); // use your own function
  cout << v3 << endl;
  v3 = v5.apply( sin);
  cout << v3 << endl;

  // Another way to scale a vector
  v3 = v1.scale( 0.1);
  cout << v1 << " : " << v3 << " " << endl;
  // scale a vector "in-place" like this
  v3( 1000., 2000., 3000.);
  v3 *= 0.1;
  cout << v3 << endl;

  v2 = v1;
  cout << v2 << " " << v1 << endl;
  v2[0] = 0.0;
  cout << v2 << " " << v1 << endl;

  v2( 1., 2., 3.);
  cout << v2.unit() << " " << v2.unit().mag() << endl;

  //======== Basic Matrix stuff
  // constructor calls
  tframes::Mat m0, m1, m2;
  tframes::Mat m3( 10., 20., 30., 40., 50., 60., 70., 80., 90.);
  tframes::Mat m4( v1, v2, v3);

  // access elements
  cout << m3[0] << endl;
  cout << m3[1][0] << " " << m3[1][1] << " " << m3[1][2] << endl;

  // simple output
  cout << m3 << endl;

  // easy way to assign (reassign) values to a Mat
  m0( v1, v2, v3);
  cout << m0 << endl;
  cout << m0( v3, v2, v1) << endl;
  cout << m0 << endl;
  m0( 1., 2., 3., 4., 5., 6., 7., 8., 9.);
  cout << m0 << endl;

  // Simple way to scale a Mat
  m1 = m0.scale( 0.1);
  cout << m0 << " : " << m1 << endl;
  // scale a Mat in-place with the shorthand operator *=
  m1 *= 10.0;
  cout << m1 << endl;

  // overloaded math
  m1 = m0 + m3;
  cout << m1 << endl;
  m4 = m1 - m3;
  cout << m4 << endl;

  // scale Mat with a scalar
  m0 = m4 * 10.0;
  cout << m0 << endl;
  m0 = m4 / 10.0;
  cout << m0 << endl;

  // simple operations
  m1 = m0.transpose();
  cout << m1 << endl;
  m2 = m1.transpose();
  cout << m2 << endl;

  // easy way to apply function to all elements of a Mat
  m0 = m2.apply( add1); // user function
  cout << m0 << endl;
  m0 = m1.apply( rand_double); // generate Mat of random #'s
  cout << m0 << endl;

  // matrix inverse
  double d = m0.det();
  cout << d << endl;
  m1 = m0.inv();
  cout << m1 << endl;
  m2 = m1 * m0;
  cout << m2 << endl;
  m3 = m2.apply( threshold); // kewl application of apply
  cout << m3 << endl;

  // Mat * Vec
  m0 = m1.apply( rand_double); // random Mat
  v0 = v0.apply( rand_double); // random Vec
  cout << m0 << endl;
  cout << v0 << endl;
  v1 = m0 * v0;
  v2 = m0.inv() * v1; // this should = v0
  cout << v2 << endl;
  cout << ( v0 - v2).apply( threshold) << endl;

  //======== Coordinate transform stuff
  const double R = 4 * atan( 1.0) / 180.0; // deg to rad

  tframes::Vec vEuler( 0., 10., 30.), vEuler_;
  vEuler *= R; // convert to rad in-place
  cout << vEuler << endl;
  tframes::Mat mDCM = vEuler.getDCM();
  tframes::Vec vECI( 100.0, 0.0, 0.0), vBody, vECI_;

  vBody = mDCM * vECI;
  cout << vBody << endl;
  vECI_ = mDCM.transpose() * vBody;
  cout << vECI_ << endl;
  vECI_ = mDCM.inv() * vBody;
  cout << vECI_ << endl;

  vEuler_ = mDCM.getEuler();
  cout << vEuler / R << endl;

  tframes::Vec vx, vy, vx_, vy_, vz, vz_;
  vx( 100., 0., 0.);
  vy( 0., 100., 0.);
  vx_ = mDCM * vx;
  vy_ = mDCM * vy;
  double x = vx_.dot( vy_); // should be zero
  cout << x << endl;
  vz_ = vx_.cross( vy_);
  vz = mDCM.transpose() * vz_ / 100.0 / 100.0; // should be ( 0, 0, 1)
  cout << vz << endl;

  //======== Quaternion stuff
  tframes::Quat q0, q1, q0_;
  tframes::Mat mDCMq;
  q0 = vEuler.getQuat();
  cout << q0 << endl;
  q0 = q0.normalize(); // need left hand assignment since
                       // NO objects operate on themselves!
  cout << q0 << endl;
  mDCMq = q0.getDCM();
  m0 = mDCMq - mDCM; // should be all 0's
  cout << m0.apply( threshold) << endl;

  q0_ = mDCM.getQuat();
  cout << q0 << endl << q0_ << endl; // should be the same

  cout << "done!\n";
  return 0;
}







