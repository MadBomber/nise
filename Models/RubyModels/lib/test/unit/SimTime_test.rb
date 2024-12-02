#!/usr/bin/env ruby
######################################################
###
##  File:  test_SimTime.rb
##  Desc:  unit test
#

require 'SimTime'

require 'test/unit' unless defined? $ZENTEST and $ZENTEST

class TestSimTime < Test::Unit::TestCase

  def test_initialize
    st = SimTime.new
    assert_instance_of SimTime, st
  end

  def test_advance_time
    st = SimTime.new
    st.advance_time
    assert st.start_time < st.sim_time
    assert_equal st.sim_time,  (st.start_time + st.step_seconds)
    st.reset
    10.times {st.advance_time}
    assert_equal st.sim_time, (st.start_time + 10 * st.step_seconds)   
  end

  def test_end_of_sim_eh
    st = SimTime.new
    assert !st.end_of_sim?
    duration_seconds = st.end_time - st.start_time
    st.step_seconds = duration_seconds
    st.advance_time
    assert st.end_of_sim?
  end

  # the now method return @offset
  def test_now
    st = SimTime.new
    assert_equal st.now,  st.offset
    10.times {st.advance_time}
    assert_equal st.now, st.offset
    assert_equal 10.0, st.now
  end

  def test_print_with_double_quotes
    st = SimTime.new
    dq = st.print_with_double_quotes
    assert_equal dq, '"01 Jul 2005 12:00:00.000"'
  end

  def test_reset
    st = SimTime.new
    assert_equal st.sim_time,  st.start_time
    10.times {st.advance_time}
    assert st.sim_time > st.start_time
    st.reset
    assert_equal st.sim_time, st.start_time
    # note that the increment is not reset to its initial value
  end

  def test_reverse_time
    st = SimTime.new
    st.advance_time
    assert (st.start_time + st.now) > st.start_time
    st.reverse_time
    assert_equal 0.0, st.now
    st.reverse_time
    assert (st.start_time + st.now) < st.start_time
  end

  def test_step_seconds_equals
    st = SimTime.new
    assert_equal 1.0, st.step_seconds
    st.step_seconds = 123.456
    assert_equal 123.456, st.step_seconds
  end
  
end ## end of class TestSimTime

