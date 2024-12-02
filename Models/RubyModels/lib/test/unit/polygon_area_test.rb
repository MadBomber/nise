#!/usr/bin/env ruby
###############################################################################
###
##  File:  test_polygon_area.rb
##  Desc:  Unit test for the PolygonArea class
#

require 'PolygonArea'

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

class TestPolygonArea < Test::Unit::TestCase

  def setup
  
    an_array = Array.new
    
    an_array << LlaCoordinate.new(38.834507000000002,46.137672000000002,0.0)
    an_array << LlaCoordinate.new(38.830521000000005,46.177554999999998,0.0)
    an_array << LlaCoordinate.new(38.872734000000001,46.547237000000003,0.0)
    an_array << LlaCoordinate.new(38.890433999999999,46.570473,0.0)
    an_array << LlaCoordinate.new(39.69632,47.990760999999999,0.0)
    an_array << LlaCoordinate.new(39.370770000000007,48.374634,0.0)
    an_array << LlaCoordinate.new(38.845173000000003,48.017741999999998,0.0)
    an_array << LlaCoordinate.new(38.436999999999998,48.879406000000003,0.0)
    an_array << LlaCoordinate.new(37.653205999999997,49.074809999999999,0.0)
    an_array << LlaCoordinate.new(36.599209000000002,51.673327999999998,0.0)
    an_array << LlaCoordinate.new(36.806572000000003,54.024132000000002,0.0)
    an_array << LlaCoordinate.new(37.340809,53.897812000000009,0.0)
    an_array << LlaCoordinate.new(37.440392000000003,54.675654999999999,0.0)
    an_array << LlaCoordinate.new(38.084327999999999,55.474193999999997,0.0)
    an_array << LlaCoordinate.new(38.272593999999998,56.754672999999997,0.0)
    an_array << LlaCoordinate.new(38.267142999999997,57.232909999999997,0.0)
    an_array << LlaCoordinate.new(37.938220999999999,57.436790000000009,0.0)
    an_array << LlaCoordinate.new(37.515450000000001,59.34782400000001,0.0)
    an_array << LlaCoordinate.new(36.624248999999999,60.370674000000001,0.0)
    an_array << LlaCoordinate.new(36.662059999999997,61.140239999999999,0.0)
    an_array << LlaCoordinate.new(36.655932999999997,61.147606000000003,0.0)
    an_array << LlaCoordinate.new(35.654110000000003,61.227215000000001,0.0)
    an_array << LlaCoordinate.new(35.613154999999999,61.276629999999997,0.0)
    an_array << LlaCoordinate.new(35.612732000000001,61.276978,0.0)
    an_array << LlaCoordinate.new(35.553341000000003,61.278576000000001,0.0)
    an_array << LlaCoordinate.new(34.522984000000001,60.745682000000002,0.0)
    an_array << LlaCoordinate.new(34.301445000000001,60.917709000000002,0.0)
    an_array << LlaCoordinate.new(34.079253999999999,60.478443000000006,0.0)
    an_array << LlaCoordinate.new(33.494514000000002,60.944991999999992,0.0)
    an_array << LlaCoordinate.new(33.143124,60.586123999999998,0.0)
    an_array << LlaCoordinate.new(31.491671,60.856898999999999,0.0)
    an_array << LlaCoordinate.new(31.375972999999998,61.712883000000005,0.0)
    an_array << LlaCoordinate.new(31.059448,61.844318000000008,0.0)
    an_array << LlaCoordinate.new(31.040825000000002,61.845703,0.0)
    an_array << LlaCoordinate.new(29.861780000000003,60.878597000000006,0.0)
    an_array << LlaCoordinate.new(29.76079,60.965248000000003,0.0)
    an_array << LlaCoordinate.new(28.640169,61.804156999999996,0.0)
    an_array << LlaCoordinate.new(28.277100000000001,62.791938999999992,0.0)
    an_array << LlaCoordinate.new(27.234278,62.782966999999999,0.0)
    an_array << LlaCoordinate.new(27.138659000000001,63.317458999999999,0.0)
    an_array << LlaCoordinate.new(26.647296999999998,63.169186000000003,0.0)
    an_array << LlaCoordinate.new(26.22814,61.847881000000001,0.0)
    an_array << LlaCoordinate.new(25.194952000000001,61.610455000000002,0.0)
    an_array << LlaCoordinate.new(25.064087000000004,61.41458500000001,0.0)
    an_array << LlaCoordinate.new(25.446456999999999,60.532253000000004,0.0)
    an_array << LlaCoordinate.new(25.783118999999999,57.311928000000002,0.0)
    an_array << LlaCoordinate.new(27.021851000000002,56.964545999999999,0.0)
    an_array << LlaCoordinate.new(27.173233,56.653480999999999,0.0)
    an_array << LlaCoordinate.new(26.499172000000002,54.786659,0.0)
    an_array << LlaCoordinate.new(26.703955000000001,53.717990999999998,0.0)
    an_array << LlaCoordinate.new(27.63768,52.446841999999997,0.0)
    an_array << LlaCoordinate.new(27.925415000000001,51.403961000000002,0.0)
    an_array << LlaCoordinate.new(30.187049999999999,50.08419,0.0)
    an_array << LlaCoordinate.new(29.997543000000004,49.559508999999998,0.0)
    an_array << LlaCoordinate.new(30.387750999999998,48.926608999999999,0.0)
    an_array << LlaCoordinate.new(30.510500000000004,49.22813,0.0)
    an_array << LlaCoordinate.new(30.497505,48.902031000000001,0.0)
    an_array << LlaCoordinate.new(30.024773000000003,48.921795000000003,0.0)
    an_array << LlaCoordinate.new(29.979868,48.484611999999998,0.0)
    an_array << LlaCoordinate.new(29.997194000000004,48.457565000000002,0.0)
    an_array << LlaCoordinate.new(30.484976,48.035046000000001,0.0)
    an_array << LlaCoordinate.new(30.993813999999997,48.030827000000002,0.0)
    an_array << LlaCoordinate.new(30.992502000000002,47.701720999999999,0.0)
    an_array << LlaCoordinate.new(31.792896000000002,47.864296000000003,0.0)
    an_array << LlaCoordinate.new(32.401176,47.448883000000002,0.0)
    an_array << LlaCoordinate.new(32.969619999999999,46.101951999999997,0.0)
    an_array << LlaCoordinate.new(33.253376000000003,46.197268999999999,0.0)
    an_array << LlaCoordinate.new(33.971558000000002,45.412762000000001,0.0)
    an_array << LlaCoordinate.new(34.591464999999999,45.535988000000003,0.0)
    an_array << LlaCoordinate.new(35.108280000000001,46.188994999999998,0.0)
    an_array << LlaCoordinate.new(35.677841000000001,46.012993000000002,0.0)
    an_array << LlaCoordinate.new(35.816208000000003,46.345150000000004,0.0)
    an_array << LlaCoordinate.new(35.818843999999999,46.342948999999997,0.0)
    an_array << LlaCoordinate.new(35.982174000000001,45.355705,0.0)
    an_array << LlaCoordinate.new(37.135016999999998,44.786754999999999,0.0)
    an_array << LlaCoordinate.new(37.148144000000002,44.804966,0.0)
    an_array << LlaCoordinate.new(37.726329999999997,44.634673999999997,0.0)
    an_array << LlaCoordinate.new(37.887112000000002,44.238861,0.0)
    an_array << LlaCoordinate.new(38.327891999999999,44.509529000000001,0.0)
    an_array << LlaCoordinate.new(39.376410999999997,44.047291000000001,0.0)
    an_array << LlaCoordinate.new(39.773356999999997,44.606552000000001,0.0)
    an_array << LlaCoordinate.new(39.639130000000002,44.813831,0.0)
    an_array << LlaCoordinate.new(39.625247999999999,44.820239999999998,0.0)
    an_array << LlaCoordinate.new(38.991782999999998,45.444023000000001,0.0)
    an_array << LlaCoordinate.new(38.840449999999997,46.123413000000006,0.0)

    @pa = PolygonArea.new(an_array)
    
    a_second_array = Array.new
    
    a_second_array << LlaCoordinate.new(26.076412, 56.088776, 0.0)
    a_second_array << LlaCoordinate.new(26.071932, 56.112301, 0.0)
    a_second_array << LlaCoordinate.new(25.630047, 56.263599, 0.0)
    a_second_array << LlaCoordinate.new(24.977919, 56.375072, 0.0)
    a_second_array << LlaCoordinate.new(24.977785, 56.371822, 0.0)
    a_second_array << LlaCoordinate.new(24.734283, 56.119564, 0.0)
    a_second_array << LlaCoordinate.new(24.930315, 55.854362, 0.0)
    a_second_array << LlaCoordinate.new(24.876476, 55.810684, 0.0)
    a_second_array << LlaCoordinate.new(24.234222, 55.779701, 0.0)
    a_second_array << LlaCoordinate.new(24.076366, 56.023933, 0.0)
    a_second_array << LlaCoordinate.new(23.965298, 55.480656, 0.0)
    a_second_array << LlaCoordinate.new(22.724195, 55.206921, 0.0)
    a_second_array << LlaCoordinate.new(22.69804, 55.211521, 0.0)
    a_second_array << LlaCoordinate.new(22.647434, 55.159611, 0.0)
    a_second_array << LlaCoordinate.new(22.497065, 55.006912, 0.0)
    a_second_array << LlaCoordinate.new(23.00111, 52.000595, 0.0)
    a_second_array << LlaCoordinate.new(23.863241, 51.75201, 0.0)
    a_second_array << LlaCoordinate.new(24.269106, 51.116367, 0.0)
    a_second_array << LlaCoordinate.new(24.395752, 51.114441, 0.0)
    a_second_array << LlaCoordinate.new(24.482944, 51.113113, 0.0)
    a_second_array << LlaCoordinate.new(24.608698, 51.26202, 0.0)
    a_second_array << LlaCoordinate.new(24.7172675326062, 54.0523552729171, 0.0)
    a_second_array << LlaCoordinate.new(24.7052400563848, 54.6677280806728, 0.0)
    a_second_array << LlaCoordinate.new(26.076412, 56.088776, 0.0)

    @pa2 = PolygonArea.new(a_second_array)
    
    # See Issue:165 in Issues web of the ISEwiki
    a_third_array = Array.new
    a_third_array << LlaCoordinate.new(29.891093, 48.630777)
    a_third_array << LlaCoordinate.new(30.057029, 46.714825)
    a_third_array << LlaCoordinate.new(28.190254, 44.689389)
    a_third_array << LlaCoordinate.new(26.924995, 45.765972)
    a_third_array << LlaCoordinate.new(24.083348, 51.404347)
    a_third_array << LlaCoordinate.new(26.199026, 52.02475)
    a_third_array << LlaCoordinate.new(27.132414, 50.108798)
    a_third_array << LlaCoordinate.new(28.79177,  48.649024)
    a_third_array << LlaCoordinate.new(29.932577, 48.630777)
    a_third_array << LlaCoordinate.new(29.891093, 48.630777)

    @pa3 = PolygonArea.new(a_third_array)
    
  end

  def test_centroid
    assert_equal LlaCoordinate,       @pa.centroid.class, 'Expected the centroid class variable to be an LlaCoordinate'
    assert_equal 0.0,                 @pa.centroid.alt
    assert_in_delta 32.5705347678763, @pa.centroid.lat, 0.0000000001, "Latitude of centroid not within delta"
    assert_in_delta 54.2907635252227, @pa.centroid.lng, 0.0000000001, "Longitude of centroid not within delta"
  end
  
  def test_centroid_inside_boundary
    assert @pa.includes?(@pa.centroid)    
    assert @pa2.includes?(@pa2.centroid)
  end

  def test_excludes_eh
    test_point  = LlaCoordinate.new(37.887112000000002, 44.238861, 0.0)
    assert (not @pa.excludes?(test_point))
  end

  def test_includes_eh
    test_point  = LlaCoordinate.new(37.887112000000002, 44.238861, 0.0)
    assert @pa.includes?(test_point)
  end
  
  # Deals with Issue:165
  def test_includes_eh_3
    test_point  = LlaCoordinate.new(26.221992, 49.949996)
    assert @pa3.includes?(test_point)
  end

end ## end of class TestPolygonArea < Test::Unit::TestCase 

