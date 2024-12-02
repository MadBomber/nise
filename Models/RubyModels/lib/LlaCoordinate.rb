################################
## Latitude, Longitude, Altitude
##
## A negative longitude is the Western hemispere.
## A negative latitude is in the Southern hemisphere.
## Altitude is in decimal meters
#

require 'rubygems'
require 'GeoDatum'
require 'geokit'      #/mappable'

=begin
module Geokit
  @@small_delta  =  0.1e-11  ## That is pretty small (used by LatLng#==)
end
=end


include Geokit

Geokit::default_units   = :kms      ## distances in units of kilometers (except altitude) which is in meters
Geokit::default_formula = :sphere
#Geokit::small_delta     = 0.1e-11   ## That is pretty small (used by LatLng#==)

def cast(thing, to_class=LlaCoordinate)

  thing_var = [nil, nil, nil]
  
  thing_var = thing if 'Array' == thing.class.to_s
 
  xrefs = [ [:@lat, :@latitude],
            [:@lng, :@lon, :@long, :@longitude],
            [:@alt, :@altitude]
  ]
  
  unless 'Array' == thing.class.to_s
    thing.instance_variables.each do |my_var|
      3.times do |x|
        inx = xrefs[x].index(my_var.to_sym)
        thing_var[x] = thing.instance_variable_get(xrefs[x][inx]) if inx and thing_var[x].nil?
      end
    end
  end
   
  new_thing = to_class.new
  
  new_thing.instance_variables.each do |my_var|
    3.times do |x|
      inx = xrefs[x].index(my_var.to_sym)
      new_thing.instance_variable_set(xrefs[x][inx], thing_var[x]) if inx and thing_var[x]
    end
  end
 
  return new_thing
  
end


#################################################
## Over-rides and extensions to Geokit::LatLng

class LatLng
  
  attr_accessor :alt
  
  def initialize(latitude_deg = 0.0, longitude_deg = 0.0, altitude_meters = 0.0)
    
    if 'Array' == latitude_deg.class.to_s
      @lat = latitude_deg[0]
      @lng = latitude_deg[1]
      @alt = latitude_deg[2]
    else
      @lat = latitude_deg
      @lng = longitude_deg
      @alt = altitude_meters
    end
    
  end ## initialize

  
  ###########################################################################
  ## Over-ride of Geokit::LatLng#==
  ## Compare latitude and longitude of points from different classes
  ## to see if they are about the same place within the context of a
  ## globally defined $small_delta such as 0.1e-11
  def ==(other)
    answer = false
    other_latlng = cast(other, LatLng)
    
    return answer if other_latlng.lat.nil? or other_latlng.lng.nil?
    
    delta_lat = self.lat - other_latlng.lat
    delta_lng = self.lng - other_latlng.lng
    
    # answer = true if delta_lat.abs <= Geokit::small_delta && delta_lng.abs <= Geokit::small_delta # 0.1e-11
    answer = true if delta_lat.abs <= 0.1e-11 && delta_lng.abs <= 0.1e-11 # 0.1e-11
    
    return answer

  end




  ############################################################
  def to_ecef(datum=WGS84)

    require 'EcefCoordinate'
    
    latitude_rad  = @lat * RAD_PER_DEG
    longitude_rad = @lng * RAD_PER_DEG

    a  = datum.a        # WGS­84 semi-major axis (equatorial) radius in meters
    b  = datum.b        # WGS­84 semi-minor axis (polar) radius in meters
    f  = datum.f
    e  = datum.e        # eccentricity of ellipsoid
    e2 = datum.e2

    n = a / (Math.sqrt( 1 - e2 * (Math.sin(latitude_rad))**2))

    cos_lat   = Math.cos(latitude_rad)
    sin_lat   = Math.sin(latitude_rad)
    cos_lon   = Math.cos(longitude_rad)
    sin_lon   = Math.sin(longitude_rad)

    x = (n + @alt) * cos_lat * cos_lon
    y = (n + @alt) * cos_lat * sin_lon
    z = (n * (1 - e2) + @alt) * sin_lat

    return EcefCoordinate.new(x, y, z)

  end ## def to_ecef

  ############################################################
  def to_ned
    ned = NedCoordinate.new
  end ## def to_ned

  ############################################################
  def to_enu
    require 'EnuCoordinate'
    enu = EnuCoordinate.new
  end ## def to_enu

  ############################################################
  def to_utm
    require 'UtmCoordinate'
    return cast(self,LatLon).to_utm
  end ## def to_utm

end  ## end of class LatLng over-rides and extensions

#######################################
## Coordinate conversion and utilities
## involving geospatial points expressed
## in latitude, longitude and altitude (meters)

class LlaCoordinate < LatLng

  ##################################
  def to_s
    return "#{@lat}, #{@lng}, #{@alt}"
  end

  ##################################
  def to_a
    return [@lat, @lng, @alt]
  end

  
  ###################################
  def join(a_string)
    return "#{@lat}#{a_string}#{@lng}#{a_string}#{@alt}"
  end
  
  ###################################
  def endpoint(*args)
  
    return cast(super)
  
  end
  
end ## class LlaCoordinate

