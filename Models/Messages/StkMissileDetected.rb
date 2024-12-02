###############################################
###
##   File:   StkMissileDetected.rb
##   Desc:   An STK Radar object has detected an STK Missile Object
##
#

require 'IseMessage'

class StkMissileDetected < IseMessage
  def initialize
    super
    desc "An STK Missile Object Detection Event"
    item(:ascii_string32,           :label_)
    item(SamsonMath::Vec3(:double), :position_)
    item(:double,                   :range_)
    item(:double,                   :azimuth_)
    item(:double,                   :elevation_)
  end
end
