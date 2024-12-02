###############################################
###
##   File:   RequestForFire.rb
##   Desc:   Request a fire mission against a specific location
##
#

require 'IseMessage'

class RequestForFire < IseMessage
  def initialize
    super
    desc "Request a fire mission against a specific target location."
    item(:ascii_string32,           :label_)
    item(SamsonMath::Vec3(:double), :target_position_)
  end
end
