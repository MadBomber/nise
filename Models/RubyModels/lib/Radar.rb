##################################################################
###
##  File:  Radar.rb
##  Desc:  should be funcitonally the same as Radar.pm
##
##  TODO: edit to Ruby coding convention

require 'LlaCoordinate'
require 'StkMessage'

class Radar
  # The default class type is for a scanning radar

  attr_accessor :name
  attr_accessor :fac_sop        ## STK Object Path; used by the StkRadarDriver for the facility component
  attr_accessor :sop            ## STK Object Path; used by the StkRadarDriver for the sensor component
  attr_accessor :active         ## Used with STK to show beam on (active=true) or off (active=false)
  attr_accessor :lla            ## LlaCoordinate
  attr_accessor :model          ## STK model (graphic)
  attr_accessor :color          ## STK color to use for beam, labels, etc.
  
  attr_accessor :azimuth
  attr_accessor :azimuth_min
  attr_accessor :azimuth_max
  attr_accessor :azimuth_delta
  attr_accessor :azimuth_rate   ## degrees per second
  attr_accessor :rpm            ## revolutions per minute
  
  attr_accessor :azimuth_scan_direction
  attr_accessor :normalizing_offset
  
  attr_accessor :max_azimuth
  attr_accessor :min_azimuth
  
  attr_accessor :elevation
  attr_accessor :elevation_min
  attr_accessor :elevation_max
  attr_accessor :elevation_delta
  attr_accessor :elevation_rate             ## degrees per second
  attr_accessor :elevation_scan_direction
  
  attr_accessor :max_elevation
  attr_accessor :min_elevation

  attr_accessor :range
  
  attr_accessor :target_type

  ######################################
  # FIXME: Add parameters to constructor
  def initialize( name,                                     ## name of the radar
                  position,                                 ## LlaCoordinate or [lat, long, alt] decimal degrees and meters
                  range_array=[3000.0, 400000.0],           ## [min, max] meters
                  azimuth_array=[340.0, 55.0, 10.0, 30.0],  ## [min, max, width, rate] degrees and degrees per second
                  elevation_array=[10.0, 65.0, 10.0, 10.0], ## [min, max, width, rate] degrees and degrees per second
                  target_type=/.*/,                         ## Regular expression to specific what types of targets the radar "sees"
                  color=$BLUE_STK_COLOR
                )

    @name             = name                    ## no spaces or punc.
    @fac_sop          = "*/Facility/#{@name}"                     ## Used by the StkRadarDriver
    @sop              = "#{@fac_sop}/Sensor/#{@name}"             ## Used by the StkRadarDriver
    @active           = true                                      ## default for all but staring radars
    @model            = 'Ground_Radar_mdl/ground-radar.mdl'
    
    case position.class.to_s
      when 'LlaCoordinate' then
        @lla              = position
      when 'Array' then
        @lla            = LlaCoordinate.new position  ## [latitude, longitude, altitude] in decimal degrees and meters
      else
        raise "Bad Class for position"
    end
    
    @rpm              = 0.0
    
    @range            = range_array             ## [min, max] meters
    @azimuth_min      = azimuth_array[0]        ## degrees
    @azimuth_max      = azimuth_array[1]        ## degrees
    @azimuth_delta    = azimuth_array[2] / 2.0  ## degrees
    @azimuth_rate     = azimuth_array[3]        ## degrees per second
        
    @elevation_min    = elevation_array[0]      ## degrees
    @elevation_max    = elevation_array[1]      ## degrees
    @elevation_delta  = elevation_array[2] / 2.0## degrees
    @elevation_rate   = elevation_array[3]      ## degrees per second
    
    @target_type      = target_type             ## The type of targets this radar can see
                                                ## Example: /icbm|scud/ means icbm or scud
                                                ## The regexp is applied to the target label/name
    
    reset

  end ## def initialize

  #########
  def reset
    
    unless @azimuth_min == @azimuth_max
      d = (@azimuth_max - @azimuth_min)
      a = d >= 0.0 ? @azimuth_min + d /2.0 : @azimuth_min + (360.0 + d) / 2.0

      @azimuth         = a
    else
      @azimuth = @azimuth_min
    end
    
    @azimuth -= 360.0 if @azimuth >= 360.0
    
    @min_azimuth     = @azimuth_min
    @max_azimuth     = @azimuth_max
    
    @azimuth_scan_direction   = 1.0
    @elevation_scan_direction = 1.0
    
    d = (@elevation_max - @elevation_min) / 2.0
    
    @elevation       = @elevation_min + d
    @min_elevation   = @elevation_min
    @max_elevation   = @elevation_max

    @normalizing_offset = @azimuth_min < @azimuth_max ? 0.0 - @azimuth_min : 360.0 - @azimuth_min
    
    @az_min_norm = 0.0
    @az_max_norm = @azimuth_max + @normalizing_offset
    
  end ## end of def Reset


  
  #########################
  def to_s
    return "#{self.pretty_inspect}"
  end
  
  
   
  #########################
  def active?
    return @active
  end

  
  #######################
  def reverse_scan(a_num)
    return a_num < 0.0 ? 1.0 : -1.0
  end


  #############################################
  def azimuth_range_enforcer

    @azimuth += 360.0 if @azimuth < 0.0
    @azimuth -= 360.0 if @azimuth >= 360.0

    a = @azimuth + @normalizing_offset
    a -= 360.0 if a >= 360.0
    
    if @azimuth_scan_direction < 0.0

      if a < @az_min_norm
        @azimuth = @azimuth_min + a.abs   ## absolute value is the over_scan to be added to az_min
        @azimuth_scan_direction = reverse_scan(@azimuth_scan_direction)
      end
      
      if a > @az_max_norm
        a = 360.0 - a
        @azimuth = @azimuth_min + a
        @azimuth_scan_direction = reverse_scan(@azimuth_scan_direction)        
      end
      
    else
    
      if a > @az_max_norm
        a = a - @az_max_norm
        @azimuth = @azimuth_max - a   ## bounce-back from az max
        @azimuth_scan_direction = reverse_scan(@azimuth_scan_direction)        
      end

    end

    @azimuth += 360.0 if @azimuth < 0.0
    @azimuth -= 360.0 if @azimuth >= 360.0
 
  end
  
  ############################
  def elevation_range_enforcer
  
    if @elevation > @elevation_max
      over_scan = @elevation - @elevation_max
      @elevation = @elevation_max - over_scan
      @elevation_scan_direction = reverse_scan(@elevation_scan_direction)
    end
    
    if @elevation < @elevation_min
      over_scan = @elevation_min - @elevation
      @elevation = @elevation_min + over_scan
      @elevation_scan_direction = reverse_scan(@elevation_scan_direction)
    end

  end



  #############
  def advance_time(delta_time=0.1)

    puts "#{__LINE__}   az: #{@azimuth} asd: #{@azimuth_scan_direction}" if $debug
    
    @azimuth     += @azimuth_rate * delta_time    * @azimuth_scan_direction
    azimuth_range_enforcer

    puts "#{__LINE__}   el: #{@elevation} esd: #{@elevation_scan_direction}" if $debug
    
    @elevation   += @elevation_rate * delta_time  * @elevation_scan_direction
    elevation_range_enforcer

  end ## end of def advance_time




  ######################
  def azimuth_constraint
    
    ac = [@azimuth - @azimuth_delta,
          @azimuth + @azimuth_delta]
          
    #return sprintf("Min %10.6f Max %10.6f", @azimuth - 5.0, @azimuth + 5.0)
    
    ac[0] += 360.0 if ac[0] < 0.0
    ac[1] -= 360.0 if ac[1] > 360.0
    
    return ac
    
  end

  ########################
  def elevation_constraint
    
    return [  @elevation - @elevation_delta,
              @elevation + @elevation_delta]
        
#    return sprintf("Min %10.6f Max %10.6f", @elevation - 5.0, @elevation + 5.0)
  end


  ####################
  # returns range in meters
  def range_to(thing)
    lla = nil
    lla = thing if 'LlaCoordinate' == thing.class.to_s
    lla = thing.lla unless lla

    if lla.nil?
      range_answer = @range[1] + 42.69## pretend its outside the maximum range
    else
      range_answer = @lla.distance_to(lla, :units => :kms, :formula => :sphere) * 1000.0
    end
    
    return range_answer
  end

  ####################
  def azimuth_to(thing)
    lla = thing if 'LlaCoordinate' == thing.class.to_s
    lla = thing.lla unless lla
    azimuth_answer = @lla.heading_to(lla)
    return(azimuth_answer)
  end

  #######################
  def elevation_to(thing)
    lla = thing if 'LlaCoordinate' == thing.class.to_s
    lla = thing.lla unless lla
    raise "Not Implemented"
  end
  
  
  
  ########################
  def within_range?(thing)
    range_to_thing = range_to(thing)
        
    debug_me("RANGE"){[:range_to_thing, :@range, "thing.to_s", "@lla.to_s"]}  if $debug
    
    return(false) if range_to_thing < @range[0]  # is it less than minimum
    return(false) if range_to_thing > @range[1]  # is it greater than maximum
    
    return(true)
  end

  #############################################
  # FIXME: Account for min and max to span zero
  def within_azimuth?(thing)
    heading = azimuth_to(thing)
    heading -= 360.0 if heading > @azimuth_max
    heading += 360.0 if heading < @azimuth_min
    
    answer0  = (@azimuth_min <= heading) && (heading <= @azimuth_max)
    answer1  = @azimuth_min <= heading
    answer2  = heading <= @azimuth_max
    
    # might need to considering normailzing the heading with
    #   @normalizing_offset
    # and then using these:
    #   @az_min_norm
    #   @az_max_norm

    debug_me("AZ"){[
      :answer0,
      :answer1,
      :answer2,
      :heading,
      "@azimuth_min",
      "@azimuth_max" 
    ]}  if $debug
    
    return answer0
    
  end

  #######################
  def within_elevation?(thing)
    rause "Not Implemented"
  end

  
  #######################
  def can_detect?(threat)
  
    return(false) unless active?

    puts "#{@name} is actively looking:" # if $debug 

 
    answer  = false
    answer  = within_range?(threat) if within_azimuth?(threat) # TODO: check performance profile to see which should be executed first



#    answer = (not (threat.intercepted? or threat.impacted?)) && answer
    
#    if answer
#      if threat.detected_by.include?(@name)
#        threat.detected_by[@name][1] = $sim_time.sim_time
#      else
#        threat.detected_by[@name] = [$sim_time.sim_time, $sim_time.sim_time]
#      end
#      threat.update_cache
#    end
   
    puts "... #{answer ? 'DETECTED' : 'nope'}" # if $debug
 
    return answer
    
  end


  ###############
  def send_to_stk
    # no-op
    raise 'Not Implemented'
    return @sop
  end


end ## end of class Radar


###########################################################
## Specialized kinds of radars

class RotatingRadar < Radar
  def initialize( name,
                  position,                                 ## LlaCoordinate or [lat, long, alt] decimal degrees and meters
                  range_array=[3000.0, 400000.0],           ## [min, max] meters
                  revolutions_per_minute=10.0,              ## RPM
                  azimuth_width=10.0,                       ## width of beam
                  elevation_array=[10.0, 65.0, 10.0, 10.0], ## [min, max, width, rate]
                  target_type=/.*/,                        ## default is everything
                  color=$BLUE_STK_COLOR
                )
                
    @name           = name
    @fac_sop        = "*/Facility/#{@name}"                     ## Used by the StkRadarDriver
    @sop            = "#{@fac_sop}/Sensor/#{@name}"             ## Used by the StkRadarDriver
    @active         = true                                      ## default for all but staring radars
    @color          = color
    @model          = 'Ground_Radar_mdl/ground-radar.mdl'
    
    case position.class.to_s
      when 'LlaCoordinate' then
        @lla        = position
      when 'Array' then
        @lla        = LlaCoordinate.new position  ## [latitude, longitude, altitude] in decimal degrees and meters
      else
        raise "Bad Class for position"
    end
    
    @rpm            = revolutions_per_minute
    
    @range          = range_array
    @azimuth        =   0.0
    @azimuth_min    =   0.0
    @azimuth_max    = 360.0
    @azimuth_delta  = azimuth_width / 2.0
    @azimuth_rate   = 6.0 * @rpm  # (RPM) converted to degrees per second

    @elevation_min    = elevation_array[0]
    @elevation_max    = elevation_array[1]
    @elevation_delta  = elevation_array[2] / 2.0
    @elevation_rate   = elevation_array[3]


    @target_type      = target_type             ## The type of targets this radar can see
                                                ## Example: /icbm|scud/ means icbm or scud
                                                ## The regexp is applied to the target label/name

    
    reset
  end


  #############################################
  def azimuth_range_enforcer
    @azimuth += 360.0 if @azimuth < 0.0
    @azimuth -= 360.0 if @azimuth >= 360.0
  end




  ###############
  def send_to_stk
    
    putstk "New / Facility #{@name}"

    putstk "SetPosition #{@fac_sop} Geodetic #{lla.join(' ')}"
    putstk "VO #{@fac_sop} Model File \"#{@model}\""
    putstk "VO #{@fac_sop} ScaleLog 1.25"
    putstk "Graphics #{@fac_sop} SetColor #{@color} Marker"
    putstk "Graphics #{@fac_sop} SetColor #{@color} Label"

    putstk "New / #{@fac_sop}/Sensor #{@name}"
    putstk "Define #{@sop} Rectangular #{@azimuth_delta*2.0} #{@elevation_delta*2.0}"
    # FIXME: What are the 0 and 90 parms:
    putstk "Point #{@sop} Spinning 0 90 90 Continuous #{@rpm} 0"
    putstk "SetConstraint #{@sop} Range Max #{range[1]}"

    return @sop
  end





end ## end of class RotatingRadar < Radar

############################################################

class StaringRadar < Radar
  def initialize( name,
                  position,                         ## LlaCoordinate or [lat, long, alt] decimal degrees and meters
                  range_array=[3000.0, 400000.0],   ## [min, max] meters
                  azimuth_array=[340.0, 10.0],      ## [center azimuth, extent to either side]
                  elevation_array=[45.0, 30.0],     ## [elevation, width]
                  target_type=/.*/,                 ## default is everything
                  color=$BLUE_STK_COLOR
                )
                
    @name     = name
    @fac_sop  = "*/Facility/#{@name}"                     ## Used by the StkRadarDriver
    @sop      = "#{@fac_sop}/Sensor/#{@name}"             ## Used by the StkRadarDriver
    @active   = true                                      ## default for all but staring radars
    @color    = color
    @model    = 'Ground_Radar_mdl/ground-radar.mdl'
    
    case position.class.to_s
      when 'LlaCoordinate' then
        @lla        = position
      when 'Array' then
        @lla        = LlaCoordinate.new position  ## [latitude, longitude, altitude] in decimal degrees and meters
      else
        raise "Bad Class for position"
    end
    
    @range          = range_array
    
    @azimuth_min    = azimuth_array[0] - azimuth_array[1]
    @azimuth_max    = azimuth_array[0] + azimuth_array[1]
    @azimuth_delta  = azimuth_array[1]
    @azimuth_rate   = 0.0
    
    @elevation_min    = elevation_array[0]
    @elevation_max    = elevation_array[0]
    @elevation_delta  = elevation_array[1] / 2.0
    @elevation_rate   = 0.0
    
    @target_type      = target_type
    
    reset
  end
  
  ################################
  def advance_time(delta_time=0.1)
    return nil
  end
  
  
  
  
  
end ## ebd of class StaringRadar < Radar 


