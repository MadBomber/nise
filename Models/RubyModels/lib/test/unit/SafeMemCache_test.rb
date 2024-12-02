#!/usr/bin/env ruby
############################################################
###
##  File:  test_SafeMemCache.rb
##  Desc:  unit tests for the SafeMemCache and StatsCollector libraries
#

require 'rubygems'
require 'pp'

require 'StatsCollecter'
require 'SafeMemCache'
require 'test/unit/testcase'

require 'test/unit' if $0 == __FILE__


##################
def log_this thing
  $stdout.puts "#{Time.now} Logged: #{thing}"
  $stdout.flush
end



##############################################################
## Use memcached for pseudo shared memory

class SharedMemory

  @@smc = nil

  def initialize(some_observable_class_instance)
  
    @@smc = SafeMemCache.new('0.0.0.0:11211', :no_reply => true) if @@smc.nil?
    
    some_observable_class_instance.add_observer(self)
    
    log_this("--------------- SharedMemory Initialized ------------------")
    
    pp @@smc
  
  end
  
  def update(key, value)
    log_this "---------------- DEBUG: setting #{key} to #{value}"
    @@smc.set(key.to_s, value)
  end

end ## end of class SharedMemory


#############################################
## Test class for the IseScenario library

class TestSafeMemCache < Test::Unit::TestCase
  
  def setup
    $debug = false
  end
  
  def teardown
  end

  ###########
  def test_01
    sc = StatsCollecter.new({:one => [0, "A One and"], :two => [0, "a two ..."] })
    
    pp sc
    
    SharedMemory.new(sc)
        
    sc.count :one
    sc.count :one
    sc.count :one
    sc.count :one
    
  end

end ## end of class TestSafeMemCache

