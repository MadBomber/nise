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

class InterceptorGenerator

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



    @lat1 = lla1.lat.to_f # starting (launch) point latitude in decimal degrees
    @lng1 = lla1.lng.to_f # starting (launch) point longitude in decimal degrees
    @alt1 = lla1.alt.to_f # starting (launch) point altitude in decimal meters

    @lat2 = lla2.lat.to_f # ending (impact) point latitude in decimal degrees
    @lng2 = lla2.lng.to_f # ending (impact) point longitude in decimal degrees
    @alt2 = lla2.alt.to_f # ending (impact) point altitude in decimal meters

    options = {
      :flight_time      =>    30.0,  # (seconds) if given, constains the trajectory to this specific TOF
      :time_step        =>    1.0,  # time step between each waypoint (seconds)
      :output_filename  =>    nil,  # if present, will be the complete path to the file to write
      :launch_time      =>    0.0   # Seconds from the beginning of the simulation when the object will start flying
    }.merge(opts)

    @flight_time     = options[:flight_time].to_f
    @d_t             = options[:time_step].to_f
    @output_filename = options[:output_filename]
    @launch_time     = options[:launch_time].to_f




    pi            = Math::PI      # 3.14159265358979
    radius_earth  = WGS84.a       # radius (major axis) of the earth (meters)
    @g             = GRAVITY_MS2   # gravity (meters/second^2)

    @lat1 = @lat1 * RAD_PER_DEG
    @lng1 = @lng1 * RAD_PER_DEG

    @lat2 = @lat2 * RAD_PER_DEG
    @lng2 = @lng2 * RAD_PER_DEG


    ###############################
    # Initial Course Calculations #
    ###############################

    if (@lng2 - @lng1) > pi
      @lng1 = @lng1 + 2*pi
    elsif (@lng2 - @lng1) < -pi
      @lng2 = @lng2 + 2*pi
    end

    d_lat = @lat2 - @lat1
    d_lng = @lng2 - @lng1

    d_phi = Math.log(Math.tan(@lat2/2.0 + QUARTER_PI)/Math.tan(@lat1/2.0 + QUARTER_PI))

    if d_lat.abs < 1e-8
      q = Math.cos(@lat1)
    else
      q = (@lat2-@lat1)/d_phi
    end

    @tc           = Math.atan2(d_lng, d_phi)
    @distance_rad = Math.sqrt((@lat2-@lat1)**2 + q**2 * (@lng2-@lng1)**2)
    @distance     = @distance_rad * radius_earth

    #################################
    # Rocket Kinematic Calculations #
    #################################

    
    @theta_init   = Math.atan( ((@alt2 - @alt1) + 0.5 * @g * @flight_time**2) / @distance)
    @v_init       = @distance / ( @flight_time * Math.cos(@theta_init) )

    @time_span    = (@launch_time .. (@launch_time + @flight_time))


  end  ## end of initialization function



  def state_at(t)

    if @time_span.include?(t)
      
      leg_percent = (t - @launch_time) / @flight_time
      dist        = leg_percent * @distance
      dist_rad    = leg_percent * @distance_rad

      alt_track   = @alt1 + @v_init * (t - @launch_time) * Math.sin(@theta_init) - 0.5 * @g * (t - @launch_time)**2

      lat_track   = @lat1 + dist_rad * Math.cos(@tc)

      d_phi = Math.log(Math.tan(lat_track/ 2.0 + QUARTER_PI)/ Math.tan(@lat1 / 2.0 + QUARTER_PI))

      if (lat_track - @lat1).abs < 1e-8
        q = Math.cos(@lat1)
      else
        q = (lat_track - @lat1) / d_phi
      end

      lng_track = @lng1 + dist_rad * Math.sin(@tc) / q

      lat_track = lat_track * DEG_PER_RAD
      lng_track = lng_track * DEG_PER_RAD

      lla_track = LlaCoordinate.new( lat_track, lng_track, alt_track)

      ## Attitude Calculations
      theta_track    = Math.atan( Math.tan(@theta_init) - @g * (t - @launch_time) / (@v_init * Math.cos(@theta_init)) )
      bearing_track  = @tc * DEG_PER_RAD
      velocity_track = @v_init / Math.cos(@theta_init) * Math.cos(theta_track)

      theta_track   *= DEG_PER_RAD

      velocity_vector = ecef_rotation( lla_track, bearing_track, theta_track, velocity_track)
      attitude_vector = ecef_rotation( lla_track, bearing_track, theta_track, 1)

      return [lla_track, velocity_vector, attitude_vector]
      
    else
      return [nil, nil, nil]
    end

  end  ## end of def state_at(t)



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

    # puts rotation_matrix00.class
    
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


end  ## end of class TrajectoryGenerator














