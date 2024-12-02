#################################################################
###
##  File: IdpTraj.rb
##  Desc: Processes a trajectory file created by the UIMDT/IDP program
##
#

require 'pathname_mods'
require 'LlaCoordinate'
require 'EcefCoordinate'

class IdpTraj

  attr_reader   :traj_rv_path
  attr_reader   :t_track
  attr_accessor :trajectory

  def initialize( filename = nil, launch_time = 0)

    raise "InvalidFileName: no filename was provided" if filename.nil?

    case filename.class.to_s
    when 'String' then
      @traj_rv_path = Pathname.new filename
    when 'Pathname' then
      @traj_rv_path = filename
    else
      raise "InvalidFileName: filename class not string or pathname."
    end

    raise "InvalidFileName: filename does not exist." unless @traj_rv_path.exist?

    earth_radius = (WGS84.a + WGS84.b) / 2.0  # Average of major/minor axis

    @t_track                = Array.new
    @trajectory             = Array.new
    @velocity_vector_track  = Array.new
    @attitude_vector_track  = Array.new
    
    # Read in the trajectory data from the traj_rv.txt file
    
    marker      = 'time, s'       # This is the first non white space entry on the line that preceeds the data
    marker_len  = marker.length
    marker_found= false

    @traj_rv_path.each_line do | a_line |
      
      if marker_found
      
        traj_columns  = a_line.split    # split the into data columns

        time = traj_columns[0].to_f.ceil.to_f + launch_time

        x_ecef = traj_columns[1].to_f
        y_ecef = traj_columns[2].to_f
        z_ecef = traj_columns[3].to_f
        
        ecef_coord  = EcefCoordinate.new x_ecef, y_ecef, z_ecef

        x_velocity = traj_columns[4].to_f
        y_velocity = traj_columns[5].to_f
        z_velocity = traj_columns[6].to_f

        velocity = traj_columns[12].to_f

        x_attitude = x_velocity / velocity
        y_attitude = y_velocity / velocity
        z_attitude = z_velocity / velocity

        # lng = Math.atan2( y_ecef, x_ecef) * 180.0 /3.14159
        # lat = Math.atan2( z_ecef, Math.sqrt(x_ecef**2 + y_ecef**2)) * 180.0 /3.14159
        # alt = Math.sqrt( x_ecef**2 + y_ecef**2 + z_ecef**2) - earth_radius # FIXME: Replace earth_radius with a function of the radius of the earth based on latitude

        @t_track                << time
        @trajectory             << ecef_coord.to_lla
        @velocity_vector_track  << [ x_velocity, y_velocity, z_velocity]
        @attitude_vector_track  << [ x_attitude, y_attitude, z_attitude]
        
      else
        # keep looking for the marker, the line before the trajectory data
        marker_found = marker == a_line.strip[0,marker_len]
      end

    end ## end of @traj_rv_path.each_line do | a_line |
             


  end ## end of def initialize(filename)
  
  
  ################################
  def write_to_file(file_name)

    file_out = File.new(file_name.to_s,  "w")

    # write each trajectory point with a time offset beginning at launch_time to the traj file
    time_offset = 0
    @trajectory.each do |a_point|

      file_out.printf("%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
        @t_track[time_offset],
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

  end ## end of def write_to_file(which_file)

  def usable?

    @trajectory.each do |a_point|
      if a_point.alt > 1000000.0
        return false
      end
    end

    return true

  end ## end of def usable?

end ## end of class IdpTraj
