#!/usr/bin/env ruby


require "InterceptorGenerator"

#a = Time.now

lla1 = LlaCoordinate.new( 0, 0, 0)
lla2 = LlaCoordinate.new( 1, 1, 0)

abt1 = InterceptorGenerator.new( lla1, lla2,
              {
                :flight_time      =>   45,  # (seconds) if given, constains the trajectory to this specific TOF
                                              #   ignores given v_init for calculated one
                :time_step        =>    1.0,  # time step between each waypoint (seconds)
                :output_filename  => nil,     # if present, will be the complete path to the file to write
                :launch_time      =>    0   # Seconds from the beginning of the simulation when the object will start flying
              })



state = abt1.state_at(1)

puts "lla: #{state[0]}"
puts "velocity: #{state[1][0]}, #{state[1][1]}, #{state[1][2]}"


#lla = LlaCoordinate.new(0,0,0)

#a = abt1.ecef_rotation( lla, 0, 90, 1)

#puts "#{a[0]} , #{a[1]} , #{a[2]}"

=begin
puts(abt1.trajectory)
puts("initial velocity: #{abt1.v_init}")
puts("flight_time: #{abt1.flight_time}")
puts(abt1.velocity)

puts abt1.t_track

puts abt1.theta_track

abt1.ecef_attitude_vectors

abt1.attitude_vector_track.each do |velocity_vector|
  puts "velocity: #{velocity_vector[0]} , #{velocity_vector[1]} , #{velocity_vector[2]} "
end
=end



#b = Time.now

#puts("run time: #{b-a}")
