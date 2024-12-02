##################
## East, North, Up

class EnuCoordinate

  attr_accessor x, y, z

  def initialize(x = 0.0, y = 0.0, z = 0.0)
    @x = x
    @y = y
    @z = z
  end ## initialize
  
  ############################################################
  def to_lla
    require 'LlaCoordinate'
    lla = LlaCoordinate,new
  end ## def to_lla
  
  ############################################################
  def to_ned
    require 'NedCoordinate'
    ned = NedCoordinate.new  
  end ## def to_ned

  ############################################################
  # Convert east, north, up coordinates (labeled e, n, u) to ECEF
  # All distances are in metres
  def to_ecef(ecef_reference_position)
    
    raise ECEF_Reference_Position_Required unless ecef_reference_position.class.to_s == 'EcefCoordinate'    

    require 'EcefCoordinate'

    x_ref = ecef_reference_position.x
    y_ref = ecef_reference_position.y
    z_ref = ecef_reference_position.z
   
    phiP = Math.atan2( z_ref, sqrt(x_ref**2 + y_ref**2) ) # Geocentric latitude
   
    # FIXME: refLong is not defined
   
    x = - Math.sin(refLong) * e - Math.cos(refLong) * Math.sin(phiP) * n + Math.cos(refLong) * Math.cos(phiP)    * u + x_ref
    y = Math.cos(refLong)   * e - Math.sin(refLong) * Math.sin(phiP) * n + Math.cos(phiP)    * Math.sin(refLong) * u + y_ref
    z = Math.cos(phiP)      * n + Math.sin(phiP)    * u + z_ref

    return EcefCoordinate.new(x, y, z)
    
  end ## def to_ecef

  ############################################################
  def to_utm
    require 'UtmCoordinate'
    utm = UtmCoordinate.new
  end ## def to_utm

end ## class EnuCoordinate

