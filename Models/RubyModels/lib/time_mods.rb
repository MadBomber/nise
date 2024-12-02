#####################################################
###
##  File:  time_mods.rb
##  Desc:  Modifications to the Time class
#

class Time

  # Used by the STK libraries
  def stkfmt
    sec_f = "#{self.sec}.#{self.usec}".to_f
    return sprintf('"%s%06.3f"', self.strftime("%d %b %Y %H:%M:"), sec_f)
  end ## end of def stkfmt

end ## class Time

