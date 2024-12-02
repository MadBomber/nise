#############################
## Earth-centric, Earth-fixed

require 'GeoDatum'

class EcefCoordinate

  attr_accessor :x, :y, :z

  def initialize(x = 0.0, y = 0.0, z = 0.0)
  
    if 'Array' == x.class.to_s
      @x = x[0]
      @y = x[1]
      @z = x[2]
    else
      @x = x
      @y = y
      @z = z
    end
    
  end ## initialize
  
  ##########################################################################
  def to_lla
  
    require 'LlaCoordinate'

    a  = WGS84.a        # WGS­84 semi-major axis (equatorial) radius in meters
    b  = WGS84.b        # WGS­84 semi-minor axis (polar) radius in meters
    f  = WGS84.f
    e  = WGS84.e        # eccentricity of ellipsoid
    e2 = WGS84.e2
    
    small_delta = 0.00000001  # Used for testing convergance

    longitude   = Math.atan2(y, x)         # long = atan(y,x) - direct
    longitude   = longitude * DEG_PER_RAD  # convert to degrees
    
    h, flag, j = 0, 0 ,0                   # initialize
    n          = a
    
    p        = Math.sqrt( x**2 + y**2)
    sin_lat  = z / ( n * ( 1 - e2 ) + h)            # First iteration
    latitude = Math.atan( ( z + e2 * n * sin_lat) / p)
    n        = a / ( Math.sqrt(1 - e2 * (sin_lat**2) ))
    prev_alt = ( p / Math.cos(latitude) ) - n
    prev_lat = latitude * DEG_PER_RAD
    
    # TODO: This while loop can be optimized
    while (flag < 2)  # do at least 100 iterations
      flag      = 0
      sin_lat   = z / ( n * ( 1 - e2 ) + h)
      latitude  = Math.atan( (z + e2 * n * sin_lat) / p)
      n         = a / (Math.sqrt(1 - e2 * (sin_lat**2) ) )
      altitude  = ( p / Math.cos(latitude) ) - n
      latitude  = latitude * DEG_PER_RAD

      flag = 1        if (prev_alt - altitude).abs < small_delta
      flag = flag + 1 if (prev_lat - latitude).abs < small_delta

      j = j + 1

      flag = 2 if j >= 100

      prev_alt = altitude
      prev_lat = latitude
    end

    return LlaCoordinate.new(latitude, longitude, altitude)
    
  end ## def to_lla
  
  ############################################################
  def to_ned
    require 'NedCoordinate'
    ned = NedCoordinate.new  
  end ## def to_ned

  ############################################################
  ## convert ECEF coordinates to local east, north, up 
  def to_enu(ecef_reference_position)
    
    raise ECEF_Reference_Position_Required unless ecef_reference_position.class.to_s == 'EcefCoordinate'
    
    require 'EnuCoordinate'
    
    x_ref = ecef_reference_position.x
    y_ref = ecef_reference_position.y
    z_ref = ecef_reference_position.z
    
    phiP     = Math.atan2(z_ref, Math.sqrt(x_ref**2 + y_ref**2))
    sin_phiP = Math.sin(phiP)
    cos_phiP = Math.cos(phiP)
    
    lambda   = Math.atan2(y_ref, x_ref)
    sin_lamda= Math.sin(lamda)
    cos_lamda= Math.cos(lamda)
    
    delta_x = @x - x_ref
    delta_y = @y - y_ref
    delta_z = @z - z_ref

    sin_lamda_times_delta_y = sin_lamda * delta_y
    cos_lamda_times_delta_x = cos_lamda * delta_x
   
    e = - sin_lamda * delta_x + cos_lamda * delta_y
    n = - sin_phiP  * cos_lamda_times_delta_x - sin_phiP * sin_lamda_times_delta_y + cos_phiP * delta_z
    u = cos_phiP    * cos_lamda_times_delta_x + cos_phiP * sin_lamda_times_delta_y + sin_phiP * delta_z

    return EnuCoordinate.new(e, n, u)

  end ## def to_enu

  ############################################################
  def to_utm
    require 'UtmCoordinate'
    utm = UtmCoordinate.new
  end ## def to_utm

end ## class EcefCoordinate

