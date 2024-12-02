#########################################################################
###
##  File: PolygonArea.rb
##  Desc: A class to support basic functions on ploygon areas
#

require 'LlaCoordinate'
require 'debug_me'

class PolygonArea

  attr_accessor :boundary
  attr_accessor :centroid

  def initialize(an_array)
  
    throw "A PolygonArea requires more than #{an_array.length} points on its boundary" unless an_array.length > 2
    
    @boundary = an_array
    @boundary << an_array[0] unless an_array.first == an_array.last # close the polygon

    array_length = @boundary.length
    @centroid = LlaCoordinate.new
    
    ## area is in square radians; its used within the centroid calculation below
    area = 0

    0.upto(array_length-2) do |index|

      area += 0.5 * ( @boundary[index].lng * @boundary[index + 1].lat \
                      - @boundary[index + 1].lng * @boundary[index].lat \
                    )

    end

    0.upto(array_length-2) do |index|

      @centroid.lng = @centroid.lng + (1 / (6.0 * area)) \
                      * ( @boundary[index].lng + @boundary[index + 1].lng ) \
                      * ( @boundary[index].lng * @boundary[index + 1].lat - @boundary[index + 1].lng * @boundary[index].lat )
                      
      @centroid.lat = @centroid.lat + (1 / (6.0 * area)) \
                      * ( @boundary[index].lat + @boundary[index + 1].lat ) \
                      * ( @boundary[index].lng * @boundary[index + 1].lat - @boundary[index + 1].lng * @boundary[index].lat )

    end

  end  ## end of def initialize(an_array)
  
  ######################################
  def includes?(a_point)

    turn_angle = 0.0
    
    # MAGIC: 2 => 1 for zero based array + 1 for looking at next(+1) point
    (@boundary.length - 2).times do |index|   

      return(true) if @boundary[index] == a_point
      return(true) if @boundary[index+1] == a_point

      d_turn_angle   = a_point.heading_to(@boundary[index + 1]) - a_point.heading_to(@boundary[index])
      d_turn_angle  += ( (d_turn_angle > 0.0) ? -360.0 : 360.0 ) if d_turn_angle.abs > 180.0
      turn_angle    += d_turn_angle

      debug_me("WATCHING TURN ANGLE") {[:index, :d_turn_angle, :turn_angle]} if $debug

    end

    return(turn_angle.abs > 180.0)

  end ## end of def includes?(a_point)

  ######################################
  def excludes?(a_point)
    return (not includes?(a_point) )
  end ## end of def excludes?(a_point)

  alias :include? :includes?
  alias :exclude? :excludes?
  alias :inside? :includes?
  alias :outside? :excludes?
  
end ## end of class PolygonArea

## end of file PolygonArea.rb
#########################################################################

