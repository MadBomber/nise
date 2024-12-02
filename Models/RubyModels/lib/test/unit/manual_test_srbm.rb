#!/usr/bin/env ruby


require "TrajectoryGenerator"

a = Time.now

lla1 = LlaCoordinate.new(20,20,0)
lla2 = LlaCoordinate.new(20.5,20.5,0)

abt1 = TrajectoryGenerator.new( lla1, lla2,
              {
                :initial_velocity =>    2000,  # initial launch velocity of missile (meters/second)
                :flight_time      =>   0.0,  # (seconds) if given, constains the trajectory to this specific TOF
                                              #   ignores given v_init for calculated one
                :maximum_altitude =>  50000,  # max altitude of the body (meters)
                :time_step        =>    1.0,  # time step between each waypoint (seconds)
                :output_filename  => nil,     # if present, will be the complete path to the file to write
                :launch_time      =>    0.0   # Seconds from the beginning of the simulation when the object will start flying
              })

=begin
puts(abt1.trajectory)
puts("initial velocity: #{abt1.v_init}")
puts("flight_time: #{abt1.flight_time}")
puts(abt1.velocity)

puts abt1.t_track

puts abt1.theta_track

abt1.ecef_attitude_vectors
=end

abt1.velocity_track.each do |velocity_vector|
  #puts "velocity: #{Math.sqrt(velocity_vector[0]**2 + velocity_vector[1]**2 + velocity_vector[2]**2)} "
  puts "velocity: #{velocity_vector}"
end

=begin
lla = LlaCoordinate.new(45,45,0)

a = abt1.ecef_rotation( lla, 45, 45, 1)

puts "#{a[0]} , #{a[1]} , #{a[2]}"


#b = Time.now

#puts("run time: #{b-a}")
=end
