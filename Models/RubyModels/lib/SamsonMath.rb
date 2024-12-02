#!/usr/bin/env ruby
#####################################################################
###
##  File:  SamsonMath.rb
##  Desc:  Helper functions to support Samson Math utilities type definitions
#

module SamsonMath
  
  Names = ['mX', 'mY', 'mZ']
  
  EulerAngles = [:double, :double, :double]   ## referenced as mX, mY and mZ
  
  def Vec3 a_sym
    return [a_sym, a_sym, a_sym]              ## referenced as mX, mY and mZ
  end

end
