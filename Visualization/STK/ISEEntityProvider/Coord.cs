using System;
using System.Collections.Generic;
using System.Text;

namespace Coord
{
    class Coord
    {
        static double a = 6378137.0000;  // WGS84_MAJOR_AXIS
        static double b = 6356752.3142;  // WGS84_MINOR_AXIS
        static double a2 = a*a;
        static double b2 = b*b;
        static double e2 =(a2-b2)/a2;
        static double ep2=(a2-b2)/b2;

        private static double N(double phi)
        {
            return a / Math.Sqrt(1 - e2 * Math.Pow(Math.Sin(phi), 2));
        }

        public static void lat_lon_alt_to_gcc(double lat, double lon, double alt, ref double x, ref double y, ref double z)
        {
            double N = Coord.N(lat);
            double P = (N + alt) * Math.Cos(lat);
            x = P * Math.Cos(lon);
            y = P * Math.Sin(lon);
            z = (N * (1 - e2) + alt) * Math.Sin(lat);
        }

        public static void gcc_to_lat_lon_alt(double x, double y, double z, ref double lat, ref double lon, ref double alt)
        {
            double p = Math.Sqrt(Math.Pow(x, 2) + Math.Pow(y, 2));
            double theta = Math.Atan(z * a / (p * b));
            lat = Math.Atan((z + ep2 * b * Math.Pow(Math.Sin(theta), 3)) / (p - e2 * a * Math.Pow(Math.Cos(theta), 3)));
            lon = Math.Atan2(y, x);
            alt = p / Math.Cos(lat) - N(lat);
        }
    }

    class LCS
    {
        double xo, yo, zo;
        double a11, a12, a13;
        double a21, a22, a23;
        double a31, a32, a33;

        

        public LCS(double lat, double lon)
        {
            a11 = Math.Cos(lon) * Math.Cos(lat);    
            a21 = Math.Sin(lon) * Math.Cos(lat);
            a31 = Math.Sin(lat);

            a12 = -Math.Sin(lon);
            a22 = Math.Cos(lon);
            a32 = 0;

            a13 = -Math.Cos(lon) * Math.Sin(lat);
            a23 = -Math.Sin(lon) * Math.Sin(lat);
            a33 = Math.Cos(lat);

            Coord.lat_lon_alt_to_gcc(lat, lon, 0.0, ref xo, ref yo, ref zo);
        }

        public void to_gcc(double n, double e, double u, ref double x, ref double y, ref double z)
        {
            x = a11 * u + a12 * e + a13 * n + xo;
            y = a21 * u + a22 * e + a23 * n + yo;
            z = a31 * u + a32 * e + a33 * n + zo;
        }

        public void to_lle(double n, double e, double u, ref double lat, ref double lon, ref double alt)
        {
            double xg=0.0, yg=0.0, zg=0.0;
            to_gcc(n, e, u, ref xg, ref yg, ref zg);
            Coord.gcc_to_lat_lon_alt(xg, yg, zg, ref lat, ref lon, ref alt);
        }

    }
}
