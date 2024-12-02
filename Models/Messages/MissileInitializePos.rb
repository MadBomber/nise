###############################################
###
##   File:   MissileInitializePos.rb
##   Desc:   Missile Initialize Position
##
##   This file was auto-generated by auto_code_msg_hpp_as_rb
#

require 'IseMessage'

class MissileInitializePos < IseMessage
  def initialize
    super
    desc "Missile Initialize Position"
     item(:double, :time_)
     item(SamsonMath::Vec3(:double), :position_)
     item(SamsonMath::EulerAngles, :attitude_)
     item(:ACE_UINT32, :unitID_)
  end
end
