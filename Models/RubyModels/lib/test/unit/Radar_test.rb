#!/usr/bin/env ruby
######################################
###
##  File:  test_radar.rb
##  Desc:  Unit test for the Radar class and sub classes 
##
require 'Radar'
require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

class TestRadar < Test::Unit::TestCase
  
  def setup
    $debug = false
  end
  
  def teardown
  end
  
  def test_advance_time
=begin
  def initialize( name,                                     ## name of the radar
                  position,                                 ## LlaCoordinate or [lat, long, alt] decimal degrees and meters
                  range_array=[3000.0, 400000.0],           ## [min, max] meters
                  azimuth_array=[340.0, 55.0, 10.0, 30.0],  ## [min, max, width, rate] degrees and degrees per second
                  elevation_array=[10.0, 65.0, 10.0, 10.0], ## [min, max, width, rate] degrees and degrees per second
                  target_type=/.*/,                         ## Regular expression to specific what types of targets the radar "sees"
                  color=$BLUE_STK_COLOR
                )

=end
    r = Radar.new(  "Test Radar",
                    [38.052438, 127.124346, 0.000000],
                    [100.0, 100000.0],
                    [25.0, 55.0, 10.0, 10.0],
                    [15.0, 65.0, 10.0, 10.0]
      )

      assert_equal 40.0, r.azimuth, "Starting azimuth"
      assert_equal 40.0, r.elevation, "Starting elevation"
      assert_equal 10.0, r.azimuth_rate
      assert_equal 10.0, r.elevation_rate
      assert_equal 1.0, r.azimuth_scan_direction
      assert_equal 1.0, r.elevation_scan_direction
   
    r.advance_time 1.0
    assert_equal 50.0, r.azimuth
    assert_equal 50.0, r.elevation
    
    r.advance_time 2.0
    assert_equal 40.0, r.azimuth, "Bounce-back on azimuth"
    assert_equal 60.0, r.elevation, "Bounch-back on elevation"

    r.advance_time 1.0
    assert_equal 30.0, r.azimuth, "azimuth in the other direction"
    assert_equal 50.0, r.elevation, "elevation in the other direction"
    
    r.advance_time 1.0
    assert_equal 30.0, r.azimuth, "bounch back off of minimum"
    assert_equal 40.0, r.elevation, "elevation in the other direction"
    
    r.advance_time 2.0
    assert_equal 50.0, r.azimuth, "azimuth in the positive direction"
    assert_equal 20.0, r.elevation, "elevation in the negative direction"
    
    r.advance_time 1.5
    assert_equal 45.0, r.azimuth, "azimuth bounce-back"
    assert_equal 25.0, r.elevation, "elevation bounce-back"
    
  end
  
  
  ######################################
  def test_advance_time_again
  
    radar_name      = "Test Radar"
    radar_location  = [38.052438, 127.124346, 0.000000] ## Lat, Long, Alt -- decimal degrees and meters
    range_data      = [3000.0, 400000.0]
    azimuth_data    = [340.0, 55.0, 10.0, 30.0]         ## [min, max, width, rate]
    elevation_data  = [10.0, 65.0, 10.0, 10.0]          ## [min, max, width, rate]

$debug = true
    r = Radar.new(radar_name, radar_location, range_data, azimuth_data, elevation_data)
$debug = false

    assert_equal 17.5, r.azimuth, "Starting azimuth"
    assert_equal 37.5, r.elevation, "Starting elevation"
    assert_equal 30.0, r.azimuth_rate
    assert_equal 10.0, r.elevation_rate
    assert_equal 1.0, r.azimuth_scan_direction
    assert_equal 1.0, r.elevation_scan_direction
   
    r.advance_time 1.0
    assert_equal 47.5, r.azimuth, "azimyth after 1 second"
    assert_equal 47.5, r.elevation, "elevation after 1 second"
    assert_equal 1.0, r.azimuth_scan_direction, "after 1 second still scanning positive"
    assert_equal 1.0, r.elevation_scan_direction, "after 1 second still scanning positive"

    r.advance_time 2.0
    assert_equal 2.5, r.azimuth, "Bounce-back on azimuth"
    assert_equal 62.5, r.elevation, "Bounch-back on elevation"
    assert_equal -1.0, r.azimuth_scan_direction, "now scanning in the negative direction"
    assert_equal -1.0, r.elevation_scan_direction, "bumped top now going down, negative"
    
    r.advance_time 1.0
    assert_equal 347.5, r.azimuth, "azimuth in the positive direction"
    assert_equal 52.5, r.elevation, "elevation in the positive direction"
    assert_equal 1.0, r.azimuth_scan_direction, "still scanning positive"
    assert_equal -1.0, r.elevation_scan_direction, "elevation is coming down"


    r.advance_time 1.0
    assert_equal 17.5, r.azimuth, "bounch back off of minimum"
    assert_equal 42.5, r.elevation, "elevation in the other direction"
    assert_equal 1.0, r.azimuth_scan_direction, "still scanning positive"
    assert_equal -1.0, r.elevation_scan_direction, "elevation is still coming down"


    
    r.advance_time 2.0
    assert_equal 32.5, r.azimuth, "azimuth in the positive direction"
    assert_equal 22.5, r.elevation, "elevation in the negative direction"
    assert_equal -1.0, r.azimuth_scan_direction, "going negative direction now"
    assert_equal -1.0, r.elevation_scan_direction, "elevation is coming down still"

    r.advance_time 1.5
    assert_equal 347.5, r.azimuth, "azimuth bounce-back"
    assert_equal 12.5, r.elevation, "elevation bounce-back"
    assert_equal -1.0, r.azimuth_scan_direction, "still going negative direction now"
    assert_equal 1.0, r.elevation_scan_direction, "elevation is going back up"



  end
  
  
  #########################
  def test_a_thousand_times
    
    r = Radar.new(  "Test Radar",
                    [38.052438, 127.124346, 0.000000],   
                    [100.0, 100000.0],
                    [25.0, 55.0, 10.0, 10.0],
                    [15.0, 65.0, 10.0, 10.0]
      )

    
    1000.times do |x|
      r.advance_time 0.1
#      puts "#{x})  #{r.azimuth}\t#{r.elevation}"
    end
    assert_equal 30.0, r.azimuth
    assert_equal 40.0, r.elevation
  end
  
  def test_rotating_radar
    
    r = RotatingRadar.new(  "Test Rotating Radar",
                            [38.052438, 127.124346, 0.000000],
                            [100.0, 100000.0],
                            10.0, 10.0,
                            [15.0, 65.0, 10.0, 10.0]
    )
    
    assert_equal 180.0, r.azimuth, "Starting azimuth"
    assert_equal 40.0, r.elevation, "Starting elevation"
    assert_equal 60.0, r.azimuth_rate, "Starting azimuth rate"
    assert_equal 10.0, r.elevation_rate, "Starting elevation rate"
    assert_equal 1.0, r.azimuth_scan_direction
    assert_equal 1.0, r.elevation_scan_direction
        
   r.advance_time 1.0
   assert_equal 240.0, r.azimuth, "first frame azimuth"
   assert_equal 50.0, r.elevation, "first frame elevation"
   
   r.advance_time 2.0
   assert_equal 0.0, r.azimuth, "Bounce-back on azimuth"
   assert_equal 60.0, r.elevation, "Bounch-back on elevation"

   r.advance_time 1.0
   assert_equal 60.0, r.azimuth, "azimuth past north"
   assert_equal 50.0, r.elevation, "elevation in the other direction"
   
   r.advance_time 1.0
   assert_equal 120.0, r.azimuth, "azimuth in the same direction"
   assert_equal 40.0, r.elevation, "elevation in the other direction"
   
   r.advance_time 2.0
   assert_equal 240.0, r.azimuth, "azimuth in the positive direction"
   assert_equal 20.0, r.elevation, "elevation in the negative direction"
   
   r.advance_time 1.5
   assert_equal 330.0, r.azimuth, "azimuth in the same direction"
   assert_equal 25.0, r.elevation, "elevation bounce-back"
    
    r.advance_time 1.0
    assert_equal 30.0, r.azimuth, "azimuth past north"
    assert_equal 35.0, r.elevation, "elevation in positive direction"

  end
  
  def test_a_thousand_times_more
=begin
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

=end    
    
    r = RotatingRadar.new(  "Test Rotating Radar",
                            [38.052438, 127.124346, 0.000000],
                            [100.0, 100000.0],
                            10.0, 10.0,
                            [15.0, 65.0, 10.0, 10.0]
    )

    
    1000.times do |x|
      r.advance_time 0.1
#      puts "#{x})  #{r.azimuth}\t#{r.elevation}"
    end
    assert_equal 6180.0 % 360.0, r.azimuth, "Ending azimuth"
    assert_equal 40.0, r.elevation, "ending elevation"
  end
  
  def test_staring_radar
=begin
class StaringRadar < Radar
  def initialize( name,
                  position,                         ## LlaCoordinate or [lat, long, alt] decimal degrees and meters
                  range_array=[3000.0, 400000.0],   ## [min, max] meters
                  azimuth_array=[340.0, 10.0],      ## [center azimuth, extent to either side]
                  elevation_array=[45.0, 15.0],     ## [elevation, extent to either side]
                  target_type=/.*/,                 ## default is everything
                  color=$BLUE_STK_COLOR
                )
=end    
    
    r = StaringRadar.new(  "Test Rotating Radar",
                           [38.052438, 127.124346, 0.000000],
                           [100.0, 100000.0],
                           [45.0, 5.0],
                           [45.0, 5.0]
    )
    
    
    assert_equal 45.0, r.azimuth, "Starting azimuth"
    assert_equal 45.0, r.elevation, "Starting elevation"
    assert_equal 0.0, r.azimuth_rate, "Starting azimuth rate"
    assert_equal 0.0, r.elevation_rate, "Starting elevation rate"
    assert_equal 1.0, r.azimuth_scan_direction
    assert_equal 1.0, r.elevation_scan_direction

    r.advance_time 1.0
    assert_equal 45.0, r.azimuth, "Staring azimuth"
    assert_equal 45.0, r.elevation, "Staring elevation"

    r.advance_time 2.0
    assert_equal 45.0, r.azimuth, "Staring azimuth"
    assert_equal 45.0, r.elevation, "Staring elevation"
 
    r.advance_time 3.0
    assert_equal 45.0, r.azimuth, "Staring azimuth"
    assert_equal 45.0, r.elevation, "Staring elevation"
   
    r.azimuth = 60.0
    r.elevation = 60.0
    
 
 r.advance_time 3.0
 assert_equal 60.0, r.azimuth, "Staring azimuth"
 assert_equal 60.0, r.elevation, "Staring elevation"
   
   assert_equal [55.0, 65.0], r.azimuth_constraint
   assert_equal [57.5, 62.5], r.elevation_constraint
   
  end
  
  def test_advance_time_across_north

    r = Radar.new(  "Test Radar",
                    [38.052438, 127.124346, 0.000000],
                    [100.0, 100000.0],
                    [340.0, 30.0, 10.0, 10.0],
                    [15.0, 65.0, 10.0, 10.0]
      )

      assert_equal 5.0, r.azimuth, "Starting azimuth"
      assert_equal 40.0, r.elevation, "Starting elevation"
      assert_equal 10.0, r.azimuth_rate
      assert_equal 10.0, r.elevation_rate
      assert_equal 1.0, r.azimuth_scan_direction
      assert_equal 1.0, r.elevation_scan_direction
   

    r.advance_time 1.0
    assert_equal 1.0, r.azimuth_scan_direction, "Should still be going positive"
    assert_equal 15.0, r.azimuth, "first azimuth in positive direction"
    assert_equal 50.0, r.elevation, "first elevation in positive direction"
 
 end 
=begin
  def test_azimuth
    raise NotImplementedError, 'Need to write test_azimuth'
  end

  def test_azimuth_constraint
    raise NotImplementedError, 'Need to write test_azimuth_constraint'
  end

  def test_azimuth_delta
    raise NotImplementedError, 'Need to write test_azimuth_delta'
  end

  def test_azimuth_delta_equals
    raise NotImplementedError, 'Need to write test_azimuth_delta_equals'
  end

  def test_azimuth_equals
    raise NotImplementedError, 'Need to write test_azimuth_equals'
  end

  def test_azimuth_max
    raise NotImplementedError, 'Need to write test_azimuth_max'
  end

  def test_azimuth_max_equals
    raise NotImplementedError, 'Need to write test_azimuth_max_equals'
  end

  def test_azimuth_min
    raise NotImplementedError, 'Need to write test_azimuth_min'
  end

  def test_azimuth_min_equals
    raise NotImplementedError, 'Need to write test_azimuth_min_equals'
  end

  def test_azimuth_rate
    raise NotImplementedError, 'Need to write test_azimuth_rate'
  end

  def test_azimuth_rate_equals
    raise NotImplementedError, 'Need to write test_azimuth_rate_equals'
  end

  def test_azimuth_scan_direction
    raise NotImplementedError, 'Need to write test_azimuth_scan_direction'
  end

  def test_azimuth_scan_direction_equals
    raise NotImplementedError, 'Need to write test_azimuth_scan_direction_equals'
  end

  def test_elevation
    raise NotImplementedError, 'Need to write test_elevation'
  end

  def test_elevation_constraint
    raise NotImplementedError, 'Need to write test_elevation_constraint'
  end

  def test_elevation_delta
    raise NotImplementedError, 'Need to write test_elevation_delta'
  end

  def test_elevation_delta_equals
    raise NotImplementedError, 'Need to write test_elevation_delta_equals'
  end

  def test_elevation_equals
    raise NotImplementedError, 'Need to write test_elevation_equals'
  end

  def test_elevation_max
    raise NotImplementedError, 'Need to write test_elevation_max'
  end

  def test_elevation_max_equals
    raise NotImplementedError, 'Need to write test_elevation_max_equals'
  end

  def test_elevation_min
    raise NotImplementedError, 'Need to write test_elevation_min'
  end

  def test_elevation_min_equals
    raise NotImplementedError, 'Need to write test_elevation_min_equals'
  end

  def test_elevation_rate
    raise NotImplementedError, 'Need to write test_elevation_rate'
  end

  def test_elevation_rate_equals
    raise NotImplementedError, 'Need to write test_elevation_rate_equals'
  end

  def test_elevation_scan_direction
    raise NotImplementedError, 'Need to write test_elevation_scan_direction'
  end

  def test_elevation_scan_direction_equals
    raise NotImplementedError, 'Need to write test_elevation_scan_direction_equals'
  end

  def test_max_azimuth
    raise NotImplementedError, 'Need to write test_max_azimuth'
  end

  def test_max_azimuth_equals
    raise NotImplementedError, 'Need to write test_max_azimuth_equals'
  end

  def test_max_elevation
    raise NotImplementedError, 'Need to write test_max_elevation'
  end

  def test_max_elevation_equals
    raise NotImplementedError, 'Need to write test_max_elevation_equals'
  end

  def test_min_azimuth
    raise NotImplementedError, 'Need to write test_min_azimuth'
  end

  def test_min_azimuth_equals
    raise NotImplementedError, 'Need to write test_min_azimuth_equals'
  end

  def test_min_elevation
    raise NotImplementedError, 'Need to write test_min_elevation'
  end

  def test_min_elevation_equals
    raise NotImplementedError, 'Need to write test_min_elevation_equals'
  end

  def test_position
    raise NotImplementedError, 'Need to write test_position'
  end

  def test_position_equals
    raise NotImplementedError, 'Need to write test_position_equals'
  end

  def test_reset
    raise NotImplementedError, 'Need to write test_reset'
  end

  def test_reverse_scan
    raise NotImplementedError, 'Need to write test_reverse_scan'
  end
  
=end


end
