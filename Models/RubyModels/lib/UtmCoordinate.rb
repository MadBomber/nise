#############################
## Universal Traverse Measure

require 'GeoDatum'
require 'geoutm'
include GeoUtm

class UTM
  attr_accessor :alt
=begin
  def initialize(latitude_deg = 0.0, longitude_deg = 0.0, altitude_meters = 0.0)
    @lat = latitude_deg
    @lng = longitude_deg
    @alt = altitude_meters
  end ## initialize
=end
end

class LatLon
  attr_accessor :alt

  def initialize(latitude_deg = 0.0, longitude_deg = 0.0, altitude_meters = 0.0)
    @lat = latitude_deg
    @lon = longitude_deg
    @alt = altitude_meters
  end ## initialize

end


class UtmCoordinate

  attr_accessor :x, :y, :z

  def initialize(x = 0.0, y = 0.0, z = 0.0)
    @x = x
    @y = y
    @z = z
  end ## initialize
  
  ############################################################
  def to_lla
    require 'LlaCoordinate'
    lla = LlaCoordinate,new
  end ## def to_lla
  
  ############################################################
  def to_ned
    require 'NedCoordinate'
    ned = NedCoordinate.new  
  end ## def to_ned

  ############################################################
  def to_enu
    require 'EnuCoordinate'
    enu = EnuCoordinate.new
  end ## def to_enu

  ############################################################
  def to_ecef
    require 'EcefCoordinate'
    ecef = EcefCoordinate.new
  end ## def to_ecef

end ## class UtmCoordinate


