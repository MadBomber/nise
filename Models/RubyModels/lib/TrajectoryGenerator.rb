################################################################
###
##  File:  TrajectoryGenerator.rb
##  Desc:  Generates a trajectory for a ballistic threat from lla1 to lla2.  This is a simple, parabolic
##         trajectory with zero drag.  The only force acting on the body is gravity.
##         You can specify the trajectory by giving an initial velocity (with the option
##         to choose a high or low trajectory), or by giving a prescribed flight time.
#


require 'LlaCoordinate'
require 'matrix'

class TrajectoryGenerator

  attr_accessor :t_track
  attr_accessor :trajectory
  attr_accessor :d_t
  attr_accessor :v_init
  attr_accessor :flight_time
  attr_accessor :theta_track
  attr_accessor :bearing_track
  attr_accessor :velocity_vector_track
  attr_accessor :attitude_vector_track
  attr_accessor :velocity_track

  def initialize( lla1, lla2, opts={})

    throw "lla1 must be of class LlaCoordinate, not #{lla1.class}" unless 'LlaCoordinate' == lla1.class.to_s
    throw "lla2 must be of class LlaCoordinate, not #{lla2.class}" unless 'LlaCoordinate' == lla2.class.to_s



    lat1 = lla1.lat.to_f # starting (launch) point latitude in decimal degrees
    lng1 = lla1.lng.to_f # starting (launch) point longitude in decimal degrees
    alt1 = lla1.alt.to_f # starting (launch) point altitude in decimal meters

    lat2 = lla2.lat.to_f # ending (impact) point latitude in decimal degrees
    lng2 = lla2.lng.to_f # ending (impact) point longitude in decimal degrees
    alt2 = lla2.alt.to_f # ending (impact) point altitude in decimal meters

    options = {
      :initial_velocity => 2239.0,  # initial launch velocity of missile (meters/second)
      :flight_time      =>    0.0,  # (seconds) if given, constains the trajectory to this specific TOF
      #   ignores given v_init for calculated one
      :maximum_altitude =>  50000,  # max altitude of the body (meters)
      :time_step        =>    1.0,  # time step between each waypoint (seconds)
      :output_filename  =>    nil,  # if present, will be the complete path to the file to write
      :launch_time      =>    0.0   # Seconds from the beginning of the simulation when the object will start flying
    }.merge(opts)

    v_init          = options[:initial_velocity].to_f
    flight_time     = options[:flight_time].to_f
    max_alt         = options[:maximum_altitude].to_f
    d_t             = options[:time_step].to_f
    output_filename = options[:output_filename]
    launch_time     = options[:launch_time].to_f

    @d_t          = d_t.to_f          # units of seconds
    @v_init       = v_init.to_f       # units of meters per second
    @flight_time  = flight_time.to_f  # units of seconds


    @trajectory     = Array.new
    @t_track        = Array.new
    @theta_track    = Array.new
    @bearing_track  = Array.new
    @velocity_track = Array.new

    pi            = Math::PI      # 3.14159265358979
    radius_earth  = WGS84.a       # radius (major axis) of the earth (meters)
    g             = GRAVITY_MS2   # gravity (meters/second^2)

    lat1 = lat1 * RAD_PER_DEG
    lng1 = lng1 * RAD_PER_DEG

    lat2 = lat2 * RAD_PER_DEG
    lng2 = lng2 * RAD_PER_DEG

    d_alt = alt2 - alt1


    ###############################
    # Initial Course Calculations #
    ###############################

    if (lng2 - lng1) > pi
      lng1 = lng1 + 2*pi
    elsif (lng2 - lng1) < -pi
      lng2 = lng2 + 2*pi
    end

    d_lat = lat2 - lat1
    d_lng = lng2 - lng1

    d_phi = Math.log(Math.tan(lat2/2.0 + QUARTER_PI)/Math.tan(lat1/2.0 + QUARTER_PI))

    if d_lat.abs < 1e-8
      q = Math.cos(lat1)
    else
      q = (lat2-lat1)/d_phi
    end

    tc            = Math.atan2(d_lng, d_phi)
    distance_rad  = Math.sqrt((lat2-lat1)**2 + q**2 * (lng2-lng1)**2)
    distance      = distance_rad * radius_earth

    #################################
    # Rocket Kinematic Calculations #
    #################################

    if @v_init != 0 && @flight_time == 0

      # a, b, and c are the coefficients of the parabola between pts 1 and 2, of the form y = ax**2 + bx + c

      b = 2 * (max_alt - alt1) / distance * (1 + Math.sqrt(1 - (alt2 - alt1)/(max_alt - alt1)))
      a = -b**2 / ( 4 * (max_alt - alt1) )
      c = alt1

      theta = Math.atan(b)

      @flight_time  = distance / ( @v_init * Math.cos(theta) )
      t_max         = (@flight_time / @d_t).floor * @d_t
      num_of_steps  = t_max / @d_t
      d_dist        = @v_init * Math.cos(theta) * @d_t
      d_dist_rad    = d_dist / radius_earth

      0.upto(num_of_steps) do |step|

        ## Location Calculations
        dist                = d_dist * step
        dist_rad            = d_dist_rad * step
        @t_track[step]      = @d_t * step + launch_time
        alt_track           = a * dist**2 + b * dist + c
        dist_percent        = step.to_f / num_of_steps.to_f

        lat_track = lat1 + dist_rad * Math.cos(tc)

        d_phi = Math.log(Math.tan(lat_track / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI))

        if (lat_track - lat1).abs < 1e-8
          q = Math.cos(lat1)
        else
          q = (lat_track - lat1) / d_phi
        end

        lng_track = lng1 + dist_rad * Math.sin(tc) / q

        lat_track = lat_track * DEG_PER_RAD
        lng_track = lng_track * DEG_PER_RAD

        if lng_track > 180.0
          lng_track = lng_track - 360
        elsif lng_track < -180.0
          lng_track = lng_track + 360
        end

        @trajectory << LlaCoordinate.new(lat_track, lng_track, alt_track)

        ## Attitude Calculations
        @theta_track[step]  = Math.atan(2 * a * dist + b) * DEG_PER_RAD
        @bearing_track[step]= tc * DEG_PER_RAD
        @velocity_track[step] = v_init * Math.cos(theta) / Math.cos(@theta_track[step] * RAD_PER_DEG)

        ## Adjust velocity_track to appease BMD_Flex
        k     = 1.66    # Multiplier at start of trajectory (multiplier moves from this to 1)
        p     = 2.0      # Polynomial term (adjusts "curve" of the line if expon? = false)
        expon = true

        if expon  # Use exponential multiplier
          velocity_adjust       = k**(1.0-dist_percent)

        else      # Use polynomial multiplier
          k = k - 1
          velocity_adjust = k * (1.0 - dist_percent)**p + 1
        end

        @velocity_track[step] = @velocity_track[step] * velocity_adjust


      end   ## end of do loop for waypoint calculation

    elsif @flight_time != 0 && @v_init == 0

      theta   = Math.atan( (d_alt + 0.5 * g * @flight_time**2) / distance)
      @v_init = distance / ( @flight_time * Math.cos(theta) )

      t_max         = (@flight_time / @d_t).floor * @d_t
      num_of_steps  = t_max / @d_t
      d_dist        = @v_init * Math.cos(theta) * @d_t / radius_earth

      0.upto(num_of_steps) do |step|

        ## Location Calculations
        dist                = d_dist * step
        @t_track[step]      = @d_t * step + launch_time
        alt_track           = alt1 + @v_init * (@t_track[step] - launch_time) * Math.sin(theta) - 0.5 * g * (@t_track[step] - launch_time)**2
        dist_percent        = step.to_f / num_of_steps.to_f

        lat_track = lat1 + dist * Math.cos(tc)

        d_phi = Math.log(Math.tan(lat_track / 2.0 + QUARTER_PI) / Math.tan(lat1 / 2.0 + QUARTER_PI))

        if (lat_track - lat1).abs < 1e-8
          q = Math.cos(lat1)
        else
          q = (lat_track - lat1) / d_phi
        end

        lng_track = lng1 + dist * Math.sin(tc) / q

        lat_track = lat_track * DEG_PER_RAD
        lng_track = lng_track * DEG_PER_RAD

        @trajectory << LlaCoordinate.new(lat_track, lng_track, alt_track)

        ## Attitude Calculations
        @theta_track[step]    = Math.atan( Math.tan(theta) - g * (@t_track[step] - launch_time) / (@v_init * Math.cos(theta)) ) * DEG_PER_RAD
        @bearing_track[step]  = tc * DEG_PER_RAD
        @velocity_track[step] = @v_init / Math.cos(theta) * Math.cos(@theta_track[step])

        ## Adjust velocity_track to appease BMD_Flex
        #k     = 2.0    # Multiplier at start of trajectory (multiplier moves from this to 1)
        k     = 1.0    # did not work so well; bmdflex impact point predicted better, but icon moved too fast on screen
                       # and had to be reset every few seconds backwards to its correct position
        p     = 2      # Polynomial term (adjusts "curve" of the line if expon? = false)
        expon = true

        if expon  # Use exponential multiplier
          velocity_adjust       = k**(1.0-dist_percent)

        else      # Use polynomial multiplier
          k = k - 1
          velocity_adjust = k * (1.0 - dist_percent)**p + 1
        end

        @velocity_track[step] = @velocity_track[step] * velocity_adjust


      end   ## end of do loop for waypoint calculation

    else

      throw "v_init: #{v_init} and flight_time: #{flight_time} are mutually exclusive."

    end

    @num_of_steps = num_of_steps

    ecef_velocity_vectors
    ecef_attitude_vectors

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

    0.upto(@num_of_steps) do |step|
      @velocity_vector_track[step] = ecef_rotation( @trajectory[step], @bearing_track[step], @theta_track[step], @velocity_track[step] )
    end

    return @velocity_vector_track

  end  ## end of def ecef_velocity_vectors

  ############################
  def ecef_attitude_vectors()
    @attitude_vector_track = Array.new

    0.upto(@num_of_steps) do |step|
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

end  ## end of class TrajectoryGenerator














