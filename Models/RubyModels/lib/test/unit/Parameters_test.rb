#!/usr/bin/env ruby
#################################################################
###
##  File: test_Parameters.rb
##  Desc: The Parameters class unit test
#

require 'rubygems'
require 'pp'
require 'pathname'

require 'Parameters'
require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

$data_dir = Pathname.new(__FILE__).realpath.dirname + 'data'



#############################################
## Test class for the IseScenario library

class TestParameters < Test::Unit::TestCase

  def setup
    $debug = false

    @test_filename  = $data_dir + 'test_Parameters.txt'

  end

  def teardown
  end

  ##############################
  def test_00_invalid_filenames

    begin
      parms = Parameters.new
      assert false, "Should catch failure to provide filename."
    rescue RuntimeError => e
      assert_equal "InvalidFileName: no filename was provided", e.message
    else
      assert false, "unexpected error"
    end


    begin
      parms = Parameters.new 'xyzzy_only_works_in_games.txt'
      assert false, "should catch invalid/non-existant file names"
    rescue RuntimeError => e
      assert_equal "InvalidFileName: filename does not exist.", e.message
    else
      assert false, "unexpected error"
    end

  end

  ################################
  def test_10_new_with_valid_filename
    parms = Parameters.new @test_filename
    assert parms, "test file #{@test_filename} must exist."
    assert_instance_of Parameters, parms

    values_hash  =  {
      :airplane_cruise_alt => "0.000000",
      :airplane_init_spd => "0.000000",
      :binary_output => "0",
      :database_name => "C:\\UIMDT\\MDS\\ScenarioGenerator\\Missile_Database_4.inp",
      :gauss_actual_value => "0.000000",
      :gauss_mc_param => "None",
      :gauss_orig_mean => "0.000000",
      :gauss_sigma => "0.000000",
      :gen_traj_version => "GenTraj_Ver_4_0_0",
      :impact_alt_act_m => "0.000000",
      :impact_alt_m => "0.000000",
      :impact_lat_act_deg => "25.275737",
      :impact_lat_deg => "25.275737",
      :impact_lon_act_deg => "55.427353",
      :impact_lon_deg => "55.427353",
      :launch_alt_act_m => "0.000000",
      :launch_alt_m => "0.000000",
      :launch_lat_act_deg => "27.265722",
      :launch_lat_deg => "27.265722",
      :launch_lon_act_deg => "55.805028",
      :launch_lon_deg => "55.805028",
      :launch_time => "0.000000",
      :mc_end_radius => "0.000000",
      :mc_start_radius => "0.000000",
      :missile_name => "SRBM",
      :msl_database_version => "4.0.0",
      :num_way_points => "0",
      :number_mc_runs => "1",
      :oblate_earth => "1",
      :orig_mc_seed => "1234567",
      :output_partial_filename =>
      "C:\\UIMDT\\MDS\\S_Generator/sandbox/Wed-Sep-02-14_18_04-2009_temp/traj",
      :rotating_earth => "1",
      :spent_stages => "1",
      :text_output => "1",
      :threat_id => "11",
      :time_inc => "1.000000",
      :tolerance => "10.000000",
      :udata_option => "17",
    :utrajtype => "0"}

    values_hash.each_pair do |k, v|
      assert eval("'#{v}' == parms.#{k}"), "#{k}'s value: #{v}"
    end

  end

end ## end of class TestParameters < Test::Unit::TestCase

