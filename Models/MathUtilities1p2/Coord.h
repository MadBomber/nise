#ifndef COORD_H_
#define COORD_H_

#define _USE_MATH_DEFINES
#include <cmath>
#include <math.h>

#include "boost/tuple/tuple.hpp"
using namespace boost::tuples;

class Radians;

class Degrees
{
public:
  Degrees():v(0.0){}
  explicit Degrees(double v):v(v){}
  Degrees(Radians& v);
  operator double() const {return v;}
  Degrees& operator=(const Radians&);
private:
  double v;
};

class Radians
{
public:
  Radians():v(0.0){}
  explicit Radians(double v):v(v){}
  Radians(const Degrees& v):v(M_PI/180.0*v){}
  operator double() const {return v;}
  Radians& operator=(const Degrees& d){v=(M_PI/180.0*d); return *this;}
private:
  double v;
};

Degrees::Degrees(Radians& v):v(180.0/M_PI*v){}
Degrees& Degrees::operator=(const Radians& r){v=(180.0/M_PI*r); return *this;}

void vmat_rot(double wXX, double wYX, double ZX, double wZY, double wZZ);

namespace coord {
  const double a=6378137.0000L;  // WGS84_MAJOR_AXIS
  const double b=6356752.3142L;  // WGS84_MINOR_AXIS
  const double a2=a*a;
  const double b2=b*b;
  const double e2=(a2-b2)/a2;
  const double ep2=(a2-b2)/b2;
  inline double N(double phi){return a/sqrt(1-e2*pow(sin(phi),2));}

  using boost::tuples::tuple;
  using boost::tuples::tie;
  using boost::tuples::make_tuple;

  tuple<double, double, double> lat_lon_alt_to_gcc(Radians lat, Radians lon, double alt)
  {
    double N=coord::N(lat);
    double P=(N+alt)*cos(lat);
    double x=P*cos(lon);
    double y=P*sin(lon);
    double z=(N*(1-e2)+alt)*sin(lat);
    return make_tuple(x,y,z);
  }

  tuple<Radians, Radians, double> gcc_to_lat_lon_alt(double x,double y,double z) //GCC
  {
    double p=hypot(x,y);
    double theta=atan(z*a/(p*b));
    double lat=atan((z+ep2*b*pow(sin(theta),3))/(p-e2*a*pow(cos(theta),3)));
    double lon=atan2(y,x);
    double alt=p/cos(lat)-N(lat);
    return make_tuple(lat,lon,alt);
  }

  tuple<Radians, Radians, Radians> lat_lon_hdg_to_psi_theta_phi(Radians lat, Radians lon, Radians hdg)
  {
    double alph=lon, beta=-lat-M_PI*0.5, gamm=hdg;
    double r11=  cos(alph)*cos(beta)*cos(gamm)-sin(alph)*sin(gamm);
    double r21=  sin(alph)*cos(beta)*cos(gamm)+cos(alph)*sin(gamm);
    double r31= -sin(beta)*cos(gamm);
    double r32=  sin(beta)*sin(gamm);
    double r33=  cos(beta);
    //vmat_rot(r11,r21,r31,r32,r33);
    double psi= atan2(r21,r11);
    double the= atan2(-r31,sqrt(r32*r32+r33*r33));
    double phi= atan2(r32,r33);
    return make_tuple( psi, the, phi);
  }

  tuple<Radians, Radians, Radians> lat_lon_hpr_to_psi_theta_phi(Radians lat, Radians lon, Radians h, Radians p, Radians r)
  {
    double alph=lon, beta=-(lat+M_PI*0.5);
    double As=sin(alph), Ac=cos(alph);
    double Bs=sin(beta), Bc=cos(beta);
    double Hs=sin(h),    Hc=cos(h);
    double Ps=sin(p),    Pc=cos(p);
    double Rs=sin(r),    Rc=cos(r);
    double r11=(Ac*Bc*Hc-As*Hs)*Pc-Ac*Bs*Ps;
    double r21=(As*Bc*Hc+Ac*Hs)*Pc-As*Bs*Ps;
    double r31=-Bs*Hc*Pc-Bc*Ps;
    double r32= Bs*Hs*Rc+(-Bs*Hc*Ps+Bc*Pc)*Rs;
    double r33=-Bs*Hs*Rs+(-Bs*Hc*Ps+Bc*Pc)*Rc;
    double psi= atan2(r21,r11);
    double the= atan2(-r31,sqrt(r32*r32+r33*r33));
    double phi= atan2(r32,r33);
    return make_tuple( psi, the, phi);
  }

  tuple<double, double, double> ned_to_xyz(Radians lat, Radians lon, double  n, double  e, double  d)
  {//xform NED to GCC aligned coordinates, co-located origins
    double psi=lon, phi=-lat;
    double c_psi=cos(psi), s_psi=sin(psi);
    double c_phi=cos(phi), s_phi=sin(phi);
    double x= -c_psi*c_phi*d - s_psi*e +c_psi*s_phi*n; //x parallel with prime meridian
    double y= -s_psi*c_phi*d + c_psi*e +s_psi*s_phi*n; //y is x rotated 90 deg east
    double z=        s_phi*d           +      c_phi*n; //z parallel with earth axis
    return make_tuple( x, y, z);
  }

  tuple<double, double, double> xyz_to_ned(Radians lat, Radians lon, double  x, double  y, double  z)
  {//xform GCC aligned coordinates to NED, co-located origins
    double psi=lon, phi=-lat;
    double c_psi=cos(psi), s_psi=sin(psi);
    double c_phi=cos(phi), s_phi=sin(phi);
    double d= -c_psi*c_phi*x -s_psi*c_phi*y + s_phi*z;
    double e=       -s_psi*x      + c_psi*y;
    double n=  c_psi*s_phi*x +s_psi*s_phi*y + c_phi*z;
    return make_tuple( n, e, d);
  }

  class LCS //local coordinate system
  {
    double xo, yo, zo;
    double a11, a12, a13;
    double a21, a22, a23;
    double a31, a32, a33;
  public:
    LCS(Radians lat, Radians lon): //psi=lon, phi=-lat
      a11(-cos(lon)*cos(lat)), a12(-sin(lon)), a13(-cos(lon)*sin(lat)),
      a21(-sin(lon)*cos(lat)), a22( cos(lon)), a23(-sin(lon)*sin(lat)),
      a31(-sin(lat))         , a32( 0)       , a33( cos(lat))
    {
      boost::tuples::tie(xo,yo,zo) = lat_lon_alt_to_gcc(lat,lon,0.0);
    }
    tuple<double, double, double> to_gcc(double n,double e,double d)
    {
      double x = a11*d + a12*e + a13*n + xo;
      double y = a21*d + a22*e + a23*n + yo;
      double z = a31*d + a32*e + a33*n + zo;
      return make_tuple( x, y, z);
    }
    tuple<double, double, double> to_gcc_delta(double n,double e,double d)
    {
      double x = a11*d + a12*e + a13*n;
      double y = a21*d + a22*e + a23*n;
      double z = a31*d + a32*e + a33*n;
      return make_tuple( x, y, z);
    }
    tuple<Radians, Radians, double> to_lle(double n,double e,double d)
    {
      double xg, yg, zg;
      tie(xg,yg,zg) = to_gcc(n,e,d);
      return gcc_to_lat_lon_alt(xg,yg,zg);
    }
    tuple<double, double, double> from_gcc(double x,double y,double z)
    {
      x-=xo; y-=yo; z-=zo;
      double d = a11*x + a21*y + a31*z;
      double e = a12*x + a22*y + a32*z;
      double n = a13*x + a23*y + a33*z;
      return make_tuple(n,e,d);
    }
    tuple<double, double, double> from_gcc_delta(double x,double y,double z)
    {
      double d = a11*x + a21*y + a31*z;
      double e = a12*x + a22*y + a32*z;
      double n = a13*x + a23*y + a33*z;
      return make_tuple(n,e,d);
    }
    tuple<double, double, double> from_lle(Radians lat, Radians lon, double alt)
    {
      double xg, yg, zg;
      boost::tuples::tie(xg,yg,zg) = lat_lon_alt_to_gcc(lat,lon,alt);
      return from_gcc(xg,yg,zg);
    }
  };
} // namespace coord

#endif

#if 0

#define VMAT_ROT_TO_PTP(type, w, psi, theta, phi)                            \
{                                                                            \
    type cos_theta;                                                          \
    type sq_cos_theta = 1.0 - (w)[Z][X]*(w)[Z][X];                           \
    type sin_psi;                                                            \
    type sin_phi;                                                            \
                                                                             \
    cos_theta = NS_SAFE_SQRT(sq_cos_theta);                                  \
    if (cos_theta == 0.0) /* Singularity here */                             \
      cos_theta = 0.000001;                                                  \
                                                                             \
    sin_psi = (w)[Y][X] / cos_theta;                                         \
    *(psi) = NS_SAFE_ASIN(sin_psi);                                          \
                                                                             \
    if ((w)[X][X] < 0.0)                                                     \
    {                                                                        \
        if (*(psi) < 0.0)                                                    \
          *(psi) = -PI - (*(psi));                                           \
        else                                                                 \
          *(psi) = PI - (*(psi));                                            \
    }                                                                        \
                                                                             \
    *(theta) = - NS_SAFE_ASIN((w)[Z][X]);                                    \
                                                                             \
    sin_phi = (w)[Z][Y] / cos_theta;                                         \
                                                                             \
    *(phi) = NS_SAFE_ASIN(sin_phi);                                          \
                                                                             \
    /* Correct for quadrant */                                               \
    if ((w)[Z][Z] < 0.0)                                                     \
    {                                                                        \
        if (*(phi) < 0.0)                                                    \
          *(phi) = -PI - (*(phi));                                           \
        else                                                                 \
          *(phi) = PI - (*(phi));                                            \
    }                                                                        \
}

#include <iostream>

using namespace std;
using namespace boost::tuples;

#define VAL(X) "  "#X": "<<X

void vmat_rot(double wXX, double wYX, double wZX, double wZY, double wZZ)
{
    double cos_theta;
    double sq_cos_theta = 1.0 - wZX*wZX;
    double sin_psi;
    double sin_phi;
double psi, theta, phi;
 
    cos_theta = sqrt(sq_cos_theta);
    if (cos_theta == 0.0) /* Singularity here */
      cos_theta = 0.000001;

    sin_psi = wYX / cos_theta;
    psi = asin(sin_psi);

    if (wXX < 0.0)
    {
        if (psi < 0.0)
          psi = -M_PI - psi;
        else
          psi = M_PI - psi;
    }

    theta = - asin(wZX);

    sin_phi = wZY / cos_theta;

    phi = asin(sin_phi);

    /* Correct for quadrant */
    if (wZZ < 0.0)
    {
        if (phi < 0.0)
          phi = -M_PI - phi;
        else
          phi = M_PI - phi;
    }
  cout<<VAL(psi)<<VAL(theta)<<VAL(phi)<<endl;
}

int main()
{
  //Degrees lat(35.6), lon(-121.1);
  Degrees lat(35+56/60.0+31.76/3600.0), lon(-(121+9/60.0+0.59/3600.0));
  //Degrees lat(0.0), lon(0.0);
  //double lat=  35.6 * M_PI/180.0;
  //double lon=-121.1 * M_PI/180.0;
  double alt= 100.0;
  double x,y,z;
  tie(x,y,z) = coord::lat_lon_alt_to_gcc(lat,lon,alt);
  cout<<VAL(x)<<VAL(y)<<VAL(z)<<endl;

  Degrees Lat, Lon;
  double Alt;
  tie(Lat,Lon,Alt) = coord::gcc_to_lat_lon_alt(x,y,z);
  cout<<VAL(Lat)<<VAL(Lon)<<VAL(Alt)<<endl;

  Radians psi, theta, phi;
  tie(psi, theta, phi) = coord::lat_lon_hdg_to_psi_theta_phi(lat, lon, Degrees(0.0));
  cout<<VAL(psi)<<VAL(theta)<<VAL(phi)<<endl;

  tie(psi, theta, phi) = coord::lat_lon_hpr_to_psi_theta_phi(lat, lon, Degrees(0.0), Degrees(0.0), Degrees(0.0));
  cout<<VAL(psi)<<VAL(theta)<<VAL(phi)<<endl;
}
#endif
