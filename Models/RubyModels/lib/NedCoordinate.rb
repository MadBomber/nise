####################
## North, East, Down

require 'GeoDatum'

class NedCoordinate

  attr_accessor :n, :e, :d

  def initialize(n = 0.0, e = 0.0, d = 0.0)
    @n = n
    @e = e
    @d = d
  end ## initialize
  
  ############################################################
  def to_lla
    require 'LlaCoordinate'
    lla = LlaCoordinate,new
  end ## def to_lla
  
  ############################################################
  def to_ecef
    require 'EcefCoordinate'
    ecef = EcefCoordinate.new  
  end ## def to_ecef

  ############################################################
  def to_enu
    require 'EnuCoordinate'
    enu = EnuCoordinate.new
  end ## def to_enu

  ############################################################
  def to_utm
    require 'UtmCoordinate'
    utm = UtmCoordinate.new
  end ## def to_utm

end ## class NedCoordinate

