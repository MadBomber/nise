################################################################
###
##  File:  AbtTrajectoryGenerator.rb
##  Desc:  Generates a trajectory for an air-breathing threat.  The trajectory
##         has no dog-legs.  It is a straight flight path from launch point to impact
##         point.  There is an assumed climb and dive phase with a cruse at altitude between
##         the climb and dive.
#


require 'LlaCoordinate'
require 'matrix'

class AbtTrajectoryGenerator

  attr_accessor :t_track
  attr_accessor :trajectory
  attr_accessor :d_t
  attr_accessor :velocity_track
  attr_accessor :bearing_track
  attr_accessor :theta_track
  attr_accessor :velocity_vector_track
  attr_accessor :attitude_vector_track

  
  # TODO: Replace that lla1 and lla2 parameters with a single generic array.
  #       The array will be 2 or more entries.  If just 2, [0] is lla1 and [1] is lla2.
  #       For more that two entries, then [].first is lla1 and p[.last is lla2 AND all other
  #       entries between first and last are way-points.  Basically we need to treat this
  #       array as an array of way-points.  A way-point is defined as a position and a velocity.
  #       The velocity is a scaler that expresses speed in meters per second beginning at that
  #       way-point.
  def initialize( lla_array, opts={})

#    throw "lla1 must be of class LlaCoordinate, not #{lla1.class}" unless 'LlaCoordinate' == lla1.class.to_s
#    throw "lla2 must be of class LlaCoordinate, not #{lla2.class}" unless 'LlaCoordinate' == lla2.class.to_s
  
    options = { :velocity         =>  240.0,  # constant cruise velocity (meters/second)
                :cruise_alt       =>  500.0,  # constant altitude at which the body cruises (meters)
                :climb_percent    =>   0.05,  # percent of range used for climb from alt1 to cruising altitude (default is 0.05, or 5%)
                :descend_percent  =>   0.05,  # percent of range used for descent from cruising altitude to alt2 (default is 0.05, or 5%) 
                :time_step        =>    1.0,  # time step between each waypoint (seconds) ie. delta_time or d_t
                :time_modifier    =>    0.0,  # 
                :output_filename  =>    nil   # if present, will be the complete path to the file to write
              }.merge(opts)

    velocity        = options[:velocity]
    cruise_alt      = options[:cruise_alt]
    climb_percent   = options[:climb_percent]
    descend_percent = options[:descend_percent]
    d_t             = options[:time_step]
    time_modifier   = options[:time_modifier]
    output_filename = options[:output_filename]
    launch_time     = options[:launch_time]
 
    @d_t      = d_t          # units of seconds
    @velocity = velocity    # units of meters per second

    @trajectory     = Array.new
    @t_track        = Array.new
    @velocity_track = Array.new
    @bearing_track  = Array.new  
    @theta_track    = Array.new

    pi            = Math::PI
    radius_earth  = WGS84.a         # (major axis) radius of the earth (meters)
    g             = GRAVITY_MS2     # gravity (meters/second^2)

    if lla_array.length == 2

      lat1 = lla_array[0][0]     # lat1: starting latitude (degrees)
      lng1 = lla_array[0][1]    # lng1: starting longiutde (degrees)
      alt1 = lla_array[0][2]     # alt1: starting elevation (meters)
      
      lat2 = lla_array[1][0]     # lat2: ending latitude (degrees)
      lng2 = lla_array[1][1]     # lng2: ending longitude (degrees)
      alt2 = lla_array[1][2]     # alt2: ending altitude (meters)

      lat1 = lat1 * RAD_PER_DEG # Convert degrees to rads
      lng1 = lng1 * RAD_PER_DEG # Convert degrees to rads
      
      lat2 = lat2 * RAD_PER_DEG # Convert degrees to rads
      lng2 = lng2 * RAD_PER_DEG # Convert degrees to rads

      d_alt = alt2 - alt1


      ###############################
      # Initial Course Calculations #
      ###############################

      d_lat = lat2 - lat1
      d_lng = lng2 - lng1

      d_phi = Math.log( Math.tan(lat2 / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI))

      if d_lat.abs < 1e-8
        q = Math.cos(lat1)
      else
        q = (lat2-lat1)/d_phi
      end

      tc            = Math.atan2(d_lng, d_phi)
      distance_rad  = Math.sqrt( (lat2 - lat1)**2 + q**2 * (lng2 - lng1)**2)
      distance      = distance_rad * radius_earth

      #################################
      # Rocket Kinematic Calculations #
      #################################

      d_dist            = d_t*(@velocity)
      d_dist_rad        = d_dist/radius_earth
      t_max_actual      = distance/(@velocity)
      t_max             = (t_max_actual/@d_t).floor*@d_t
      time_round_factor = t_max/t_max_actual

      if time_modifier > 0.0 && time_modifier < t_max_actual  # Create only initial portion of trajectory

        num_of_steps    = time_modifier / @d_t
        dist_offset     = 0
        dist_rad_offset = 0

      elsif time_modifier < 0.0 && time_modifier.abs < t_max_actual  # Create only final portion of trajectory

        num_of_steps    = time_modifier.abs / @d_t
        dist_offset     = distance - d_dist * num_of_steps
        dist_rad_offset = distance_rad - d_dist_rad * num_of_steps
        
      else     # create full trajectory
      
        num_of_steps    = t_max / @d_t
        dist_offset     = 0
        dist_rad_offset = 0
        
      end
      
      climb_dist    = distance*climb_percent
      descend_dist  = distance*descend_percent
      climb_end     = climb_dist
      descend_start = distance - descend_dist

      climb_angle   = (cruise_alt - alt1) / climb_dist
      descend_angle = (alt2 - cruise_alt) / descend_dist

      0.upto(num_of_steps) do |step|
      
        @t_track[step] = @d_t * step  

        dist      = d_dist * step + dist_offset
        dist_rad  = d_dist_rad * step + dist_rad_offset
        lat_track = lat1 + dist_rad * Math.cos(tc)
        d_phi     = Math.log( Math.tan(lat_track / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI) )

        if (lat_track - lat1).abs < 1e-8
          q = Math.cos(lat1)
        else
          q = (lat_track - lat1) / d_phi
        end
        
        lng_track = lng1 + dist_rad * Math.sin(tc) / q
        
        lat_track = lat_track * DEG_PER_RAD # Convert rads to degrees
        lng_track = lng_track * DEG_PER_RAD # Convert rads to degrees

        if dist >= 0 && dist < climb_end
        
          # Body is climbing
          alt_track = dist*climb_angle + alt1
          elevation = Math.atan( climb_angle ) * DEG_PER_RAD
        
        elsif dist >= climb_end && dist <= descend_start
        
          # Body is at cruise altitude
          alt_track = cruise_alt
          elevation = 0.0
        
        elsif dist >  descend_start
        
          # Body is descending
          alt_track = (dist - descend_start) * descend_angle + cruise_alt
          elevation = Math.atan( descend_angle ) * DEG_PER_RAD

        end

        bearing   = tc * DEG_PER_RAD


        @trajectory     << LlaCoordinate.new( lat_track, lng_track, alt_track)
        @velocity_track << velocity
        @bearing_track  << bearing
        @theta_track    << elevation
            
        
      end  ## end of do loop for each waypoint

    ecef_velocity_vectors  ## creates an array of velocity vectors
    ecef_attitude_vectors  ## creates an array of attitude vectors

    elsif lla_array.length > 2



      lla_array[0][4] = 0.0
      lla_array[0][5] = 0.0
      lla_array[0][6] = 0.0

      ###############################
      # Initial Course Calculations #
      ###############################

      1.upto(lla_array.length - 1) do |index|

        lat1 = lla_array[index-1][0] * RAD_PER_DEG # Convert degrees to rads
        lng1 = lla_array[index-1][1] * RAD_PER_DEG # Convert degrees to rads
        
        lat2 = lla_array[index][0] * RAD_PER_DEG # Convert degrees to rads
        lng2 = lla_array[index][1] * RAD_PER_DEG # Convert degrees to rads

        d_lat = lat2 - lat1
        d_lng = lng2 - lng1

        d_phi = Math.log( Math.tan(lat2 / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI))

        if d_lat.abs < 1e-8
          q = Math.cos(lat1)
        else
          q = (lat2-lat1)/d_phi
        end

        tc            = Math.atan2(d_lng, d_phi)
        distance_rad  = Math.sqrt( (lat2 - lat1)**2 + q**2 * (lng2 - lng1)**2)
        distance      = distance_rad * radius_earth

        lla_array[index][4] = distance + lla_array[index-1][4]                        # Total distance along track to this point
        lla_array[index][5] = tc                                                      # Bearing to get from last point to this point
        lla_array[index][6] = distance/lla_array[index-1][3] + lla_array[index-1][6]  # Total time along track to this point (leg_distance/leg_velocity + last time)

      end


      lla_array_end_time = lla_array[-1][6]

      #################################
      #   Step-by-Step Calculations   #
      #################################

      lla_array_time = Array.new

      if time_modifier > 0.0 && time_modifier < lla_array_end_time  # Create only initial portion of trajectory

        next_time = 0.0

        while next_time <= time_modifier
          lla_array_time << next_time
          @t_track       << next_time

          next_time += @d_t
        end
          

      elsif time_modifier < 0.0 && time_modifier.abs < lla_array_end_time  # Create only final portion of trajectory

        next_time       = lla_array_end_time + time_modifier
        next_track_time = 0.0

        while next_time <= lla_array_end_time
          lla_array_time << next_time
          @t_track       << next_track_time

          next_time       += @d_t
          next_track_time += @d_t
        end
        
      else     # create full trajectory
      
        next_time = 0.0

        while next_time <= lla_array_end_time
          lla_array_time << next_time
          @t_track       << next_time

          next_time += @d_t
        end
        
      end

      index = 1

      lla_array_time.each do |lla_array_time|
      
        while lla_array_time > lla_array[index][6]
          index += 1
        end      

        lat1  = lla_array[index-1][0] * RAD_PER_DEG
        lng1  = lla_array[index-1][1] * RAD_PER_DEG
        alt1  = lla_array[index-1][2]
        dist1 = lla_array[index-1][4]
        time1 = lla_array[index-1][6]

        lat2  = lla_array[index][0] * RAD_PER_DEG
        lng2  = lla_array[index][1] * RAD_PER_DEG
        alt2  = lla_array[index][2]
        dist2 = lla_array[index][4]
        time2 = lla_array[index][6] 

        tc = lla_array[index][5]

        leg_percent = (lla_array_time - time1)/(time2 - time1)

        dist      = (dist2 - dist1) * leg_percent
        dist_rad  = dist / radius_earth

        lat_track = lat1 + dist_rad * Math.cos(tc)

        d_phi     = Math.log( Math.tan(lat_track / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI) )

        if (lat_track - lat1).abs < 1e-8
          q = Math.cos(lat1)
        else
          q = (lat_track - lat1) / d_phi
        end
        
        lng_track = lng1 + dist_rad * Math.sin(tc) / q
        
        lat_track = lat_track * DEG_PER_RAD # Convert rads to degrees
        lng_track = lng_track * DEG_PER_RAD # Convert rads to degrees

        alt_track = (alt2 - alt1) * leg_percent + alt1

        velocity2 = lla_array[index-1][3]
        bearing   = tc * DEG_PER_RAD
        elevation = Math.atan2( (alt2 - alt1) , (dist2 - dist1) ) * DEG_PER_RAD

        @trajectory     << LlaCoordinate.new( lat_track, lng_track, alt_track)
        @velocity_track << velocity2
        @bearing_track  << bearing
        @theta_track    << elevation


        
      end  ## end of do loop for each waypoint

      
    end  ## end of if statement to decide between straight flight or prescribed flight plan

    ecef_velocity_vectors  ## creates an array of velocity vectors
    ecef_attitude_vectors  ## creates an array of attitude vectors

#    t_track.map! {|sim_time| launch_time + sim_time}
    
    write_to_csv_file(output_filename) if output_filename

  end  ## end of initialization function

  ################################
  def write_to_csv_file(file_name)

    file_out = File.new(file_name.to_s,  "w")
            
    # write each trajectory point with a time offset beginning at launch_time to the traj file
    time_offset = 0
    @trajectory.each do |a_point|

      file_out.printf("%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
        t_track[time_offset],
        a_point.lat,
        a_point.lng,
        a_point.alt,
        @velocity_vector_track[time_offset][0],
        @velocity_vector_track[time_offset][1],
        @velocity_vector_track[time_offset][2],
        @attitude_vector_track[time_offset][0],
        @attitude_vector_track[time_offset][1],
        @attitude_vector_track[time_offset][2]
      )
      time_offset += 1

    end ## end of @trajectory.each do |a_point|

    file_out.close     # close traj the file

  end ## end of def write_to_csv_file(which_file)


  ###########################
  def ecef_velocity_vectors()
    @velocity_vector_track = Array.new

    num_of_steps = @velocity_track.length - 1

    0.upto(num_of_steps) do |step|
      @velocity_vector_track[step] = ecef_rotation( @trajectory[step], @bearing_track[step], @theta_track[step], @velocity_track[step] )

    end

    return @velocity_vector_track

  end  ## end of def ecef_velocity_vectors

  ############################
  def ecef_attitude_vectors()
    @attitude_vector_track = Array.new

    num_of_steps = @velocity_track.length - 1

    0.upto(num_of_steps) do |step|
      @attitude_vector_track[step] = ecef_rotation( @trajectory[step], @bearing_track[step], @theta_track[step], 1.0 )
    end

    return @attitude_vector_track

  end  ## end of ecef_attitude_matrices


  ###################################################################
  def ecef_rotation(  lla, bearing = 0, elevation = 0, x_velocity = nil)

    lat = lla.lat*RAD_PER_DEG
    lng = lla.lng*RAD_PER_DEG
    phi = bearing*RAD_PER_DEG
    theta = elevation*RAD_PER_DEG

=begin
    rotate_to_ecef = Matrix[ [ 0 , 0 , 1 ],
                             [ 0 ,-1 , 0 ],
                             [ 1 , 0 , 0 ] ]
    
    lng_rotate = Matrix[ [ 1 ,        0      ,      0       ],
                         [ 0 ,  Math.cos(lng),-Math.sin(lng)],
                         [ 0 ,  Math.sin(lng), Math.cos(lng)] ]

    lat_rotate = Matrix[ [ Math.cos(lat), 0 , Math.sin(lat)],
                         [      0       , 1 ,       0      ],
                         [-Math.sin(lat), 0 , Math.cos(lat)] ]

    bearing_rotate = Matrix[ [ Math.cos(phi) ,  Math.sin(phi) , 0 ],
                             [-Math.sin(phi) ,  Math.cos(phi) , 0 ],
                             [      0        ,       0        , 1 ] ]

    elev_rotate = Matrix[ [ Math.cos(theta) , 0 , -Math.sin(theta) ],
                          [       0         , 1 ,         0        ],
                          [ Math.sin(theta) , 0 ,  Math.cos(theta) ] ]

    rotation_matrix = rotate_to_ecef * lng_rotate * lat_rotate * bearing_rotate * elev_rotate
=end

    rotation_matrix00 = -Math.sin(lat)*Math.cos(lng)*Math.cos(phi)*Math.cos(theta) - Math.sin(lng)*Math.sin(phi)*Math.cos(theta) + Math.cos(lat)*Math.cos(lng)*Math.sin(theta)
    #rotation_matrix01 = -Math.sin(lat)*Math.cos(lng)*Math.sin(phi) + Math.sin(lng)*Math.cos(phi)
    #rotation_matrix02 = Math.sin(lat)*Math.cos(lng)*Math.cos(phi)*Math.sin(theta) + Math.sin(lng)*Math.sin(phi)*Math.sin(theta) + Math.cos(lat)*Math.cos(lng)*Math.cos(theta)
    
    rotation_matrix10 = -Math.sin(lat)*Math.sin(lng)*Math.cos(phi)*Math.cos(theta) + Math.cos(lng)*Math.sin(phi)*Math.cos(theta) + Math.cos(lat)*Math.sin(lng)*Math.sin(theta)
    #rotation_matrix11 = -Math.sin(lat)*Math.sin(lng)*Math.sin(phi) - Math.cos(lng)*Math.cos(phi)
    #rotation_matrix12 = Math.sin(lat)*Math.sin(lng)*Math.cos(phi)*Math.sin(theta) - Math.cos(lng)*Math.sin(phi)*Math.sin(theta) + Math.cos(lat)*Math.sin(lng)*Math.cos(theta)

    rotation_matrix20 = Math.cos(lat)*Math.cos(phi)*Math.cos(theta) + Math.sin(lat)*Math.sin(theta)
    #rotation_matrix21 = Math.cos(lat)*Math.sin(phi)
    #rotation_matrix22 = -Math.cos(lat)*Math.cos(phi)*Math.sin(theta) + Math.sin(lat)*Math.cos(theta)

    #rotation_matrix = Matrix[  [rotation_matrix00, rotation_matrix01, rotation_matrix02],
    #                           [rotation_matrix10, rotation_matrix11, rotation_matrix12],
    #                           [rotation_matrix20, rotation_matrix21, rotation_matrix22] ]

    a = rotation_matrix00 * x_velocity
    b = rotation_matrix10 * x_velocity
    c = rotation_matrix20 * x_velocity

    return [ a, b, c]

=begin
    if vector
      if vector.class.to_s == 'Array'
        vector = Matrix.column_vector(vector)
      end
      return (rotation_matrix * vector).transpose.to_a[0]
    else
      return rotation_matrix
    end
=end
  end ## end of def ecef_rotation


  ################################
  def lat(t)
    array_index = (t / @d_t).to_i
    return @trajectory[array_index].lat
  end

  ################################
  def lng(t)
    array_index = (t / @d_t).to_i
    return @trajectory[array_index].lng
  end

  ################################
  def alt(t)
    array_index = (t / @d_t).to_i
    return @trajectory[array_index].alt
  end

end   ## end of class AbtTrajectoryGenerator

=begin
# Each entry of a flight plan has the following elements:
# lattitude(degrees), longitude (degrees), altitude (meters), speed (kilometers/hour)

flight_plan_1 = [ 
  [28.974459,  50.819251,  4572.000000,  300.000000],
  [28.705869,  50.516204,  4572.000000,  300.000000],
  [28.354911,  50.320332,  4572.000000,  300.000000],
  [27.996792,  50.142939,  4572.000000,  300.000000],
  [27.602860,  49.910110,  4572.000000,  300.000000],
  [27.245720,  49.700125,  4572.000000,  300.000000],
  [27.158930,  49.741131,  4572.000000,  300.000000],
  [27.177752,  49.841488,  4572.000000,  300.000000],
  [27.553147,  50.015223,  4572.000000,  300.000000],
  [27.966635,  50.287112,  4572.000000,  300.000000],
  [28.310013,  50.477254,  4572.000000,  300.000000],
  [28.657578,  50.680361,  4572.000000,  300.000000],
  [28.915111,  50.898592,  4572.000000,  300.000000]
]


flight_plan_2 = [
  [28.912510,  50.801860,  4572.000000,  300.000000],
  [28.687609,  50.551775,  4572.000000,  300.000000],
  [28.531437,  50.452390,  4572.000000,  300.000000],
  [28.203477,  50.277795,  4572.000000,  300.000000],
  [27.875517,  50.103200,  4572.000000,  300.000000],
  [27.521528,  49.891000,  4572.000000,  300.000000],
  [27.341835,  49.783599,  4572.000000,  300.000000],
  [27.256504,  49.739026,  4572.000000,  300.000000],
  [27.205938,  49.784686,  4572.000000,  300.000000],
  [27.295482,  49.859699,  4572.000000,  300.000000],
  [27.488266,  49.958630,  4572.000000,  300.000000],
  [27.849619,  50.166998,  4572.000000,  300.000000],
  [28.184931,  50.361345,  4572.000000,  300.000000],
  [28.515649,  50.536731,  4572.000000,  300.000000],
  [28.655745,  50.643385,  4572.000000,  300.000000],
  [28.857851,  50.984677,  4572.000000,  300.000000]
]


flight_plan_3 = [
  [28.943976,  50.807001,  4572.000000,  300.000000],
  [28.803802,  50.658328,  4572.000000,  300.000000],
  [28.613010,  50.497600,  4572.000000,  300.000000],
  [28.126295,  50.232398,  4572.000000,  300.000000],
  [27.869310,  50.107834,  4572.000000,  300.000000],
  [27.585069,  50.160070,  4572.000000,  300.000000],
  [26.903668,  50.264544,  4572.000000,  300.000000],
  [26.798538,  50.276598,  4572.000000,  300.000000],
  [26.786857,  50.405181,  4572.000000,  300.000000],
  [26.911456,  50.469472,  4572.000000,  300.000000],
  [28.850527,  50.983803,  4572.000000,  300.000000]
]

=end

