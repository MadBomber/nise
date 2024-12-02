#########################################################################
###
##  File: CircleArea.rb
##  Desc: A class to support basic functions on circle-shaped areas
#

require 'LlaCoordinate'

class CircleArea

  attr_accessor :centroid
  attr_accessor :radius

  def initialize( center, radius )

    @centroid = center  # LLA point
    @radius   = radius  # in units of meters

  end  ## end of def initialize(an_array)
  
  ######################################
  def includes?(a_point)

    distance = @centroid.distance_to(a_point) * 1000.0  # in units of meters

    return ( distance <= radius )

  end ## end of def includes?(a_point)

  ######################################
  def excludes?(a_point)
    return (not includes?(a_point) )
  end ## end of def excludes?(a_point)

  alias :include? :includes?
  alias :exclude? :excludes?
  alias :inside? :includes?
  alias :outside? :excludes?
  
end ## end of class CircleArea


## end of file CircleArea.rb
#########################################################################

