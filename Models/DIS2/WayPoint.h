#ifndef WAYPOINT_H_
#define WAYPOINT_H_

#include "Coord.h"

const double RE = 6371.0;
const double PI = 4.0*atan(1.0);


class WayPoint 
{ 
private:
	Radians lon_; 
	Radians lat_; 
	double alt_; 
	double grnd_spd_;
	Radians brng_;
	double time_;
	double d2n_;	// distance to next waypoint
	
public:
	WayPoint (Degrees lon, Degrees lat): 
		lon_(lon), lat_(lat), alt_(0.0), grnd_spd_(0.0), brng_(0.0), time_(0.0), d2n_(0.0) { }
	WayPoint (Radians lon, Radians lat): 
		lon_(lon), lat_(lat), alt_(0.0), grnd_spd_(0.0), brng_(0.0), time_(0.0), d2n_(0.0) { }
	WayPoint (double lon, double lat): 
		lon_(Degrees(lon)), lat_(Degrees(lat)), alt_(0.0), grnd_spd_(0.0), brng_(0.0), time_(0.0), d2n_(0.0) { }
	WayPoint (double lon, double lat, double alt, double grnd_spd): 
		lon_(Degrees(lon)), lat_(Degrees(lat)), alt_(alt), grnd_spd_(grnd_spd), brng_(0.0), time_(0.0), d2n_(0.0) { }
	WayPoint():
		lon_(0.0), lat_(0.0), alt_(0.0), grnd_spd_(0.0), brng_(0.0), time_(0.0), d2n_(0.0) { }
	
	Radians lat() { return lat_; } 
	void lat(double lat) { lat_ = Radians(lat); }
	void lat(Degrees lat) { lat_ = lat; }
	void lat(Radians lat) { lat_ = Radians(lat); }

	Radians lon() { return lon_; } 
	void lon(double lon) { lon_ = Radians(lon); }
	void lon(Degrees lon) { lon_ = lon; }
	void lon(Radians lon) { lon_ = Radians(lon); }

	double alt() { return alt_; } 
	void alt(double alt) { alt_ = alt; }

	Radians bearing() { return brng_; } 
	void bearing (double brng) { brng_ = Radians(brng); }

	Radians bearing(WayPoint &a2)
	{
		double dLon = (double(a2.lon_)- double(lon_));

		double y = sin(dLon) * cos(a2.lat_);
		double x = cos(lat_)*sin(a2.lat_) -
	          sin(lat_)*cos(a2.lat_)*cos(dLon);
		double a  = atan2(y, x);
		if ( a < 0.0 ) a += 2*PI;
		brng_ = Radians(a);
		return brng_;
	}
	
	double distance() { return d2n_; } 
	void distance (double d2n) { d2n_ = d2n; }

	double distance(WayPoint &a2)
	{
		d2n_ = dist_haversine (a2);
		return d2n_;
	}
	
	double time() { return time_; } 
	void time(double time) { time_ = time; }

	double grnd_spd() { return grnd_spd_; } 
	void grnd_spd(double grnd_spd) { grnd_spd_ = grnd_spd; }

	/*
	 * calculate destination point given start point, initial bearing (deg) and distance (km)
	 *   see http://williams.best.vwh.net/avform.htm#LL
	 */
	WayPoint *destPoint (double dist) 
	{
		double tlat = asin( sin(lat_)*cos(dist/RE) + cos(lat_)*sin(dist/RE)*cos(brng_) );
		double tlon = lon_ + atan2( sin(brng_)*sin(dist/RE)*cos(lat_), cos(dist/RE)-sin(lat_)*sin(tlat) );
		if ( tlon < 0.0 ) tlon = (tlon+2.0*PI);

		WayPoint *temp = new WayPoint(Radians(tlat),Radians(tlon));
		return temp;
	}

	/*
	 * Use Haversine formula to Calculate distance (in km) between two points specified by 
	 * latitude/longitude (in numeric degrees)


        double dlon_2 = ((to.lon_-lon_)/2.0);
        double dlat_2 = ((to.lat_-lat_)/2.0);
        double a = sin(dlat_2)*sin(dlat_2)+ cos(lat_)*cos(to.lat_)*sin(dlon_2)*sin(dlon_2);
        double c = 2.0 * atan2(sqrt(a), sqrt(1-a));
        return RE * c;

	 */
	double dist_haversine(WayPoint &to)
	{
		double dlon_2 = (to.lon_-lon_)/2.0;
		double dlat_2 = (to.lat_-lat_)/2.0;
		double a = sin(dlat_2)*sin(dlat_2)+ cos(lat_)*cos(to.lat_)*sin(dlon_2)*sin(dlon_2);
		double c = 2.0 * atan2(sqrt(a), sqrt(1-a));
		return RE * c;
	}
	
	void print (void)
	{
		ACE_DEBUG((LM_DEBUG, "WayPoint: T%f (%f,%f,%f) D%f B%f V%f\n", 
				time_, double(Degrees(lat_)), double(Degrees(lon_)), alt_, d2n_, double(Degrees(brng_)),  grnd_spd_
		));
	}
};

#endif /*WAYPOINT_H_*/
