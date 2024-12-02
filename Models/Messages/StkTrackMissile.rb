###############################################
###
##   File:   StkTrackMissile.rb
##   Desc:   An STK Radar object has detected an STK Missile Object
##
#

require 'IseMessage'

class StkTrackMissile < IseMessage
  def initialize
    super
    desc "An STK Missile Object Detection Event"
    item(:ascii_string32,           :label_)
    item(SamsonMath::Vec3(:double), :position_)
    item(:double,                   :range_)
  end
end
