#!/usr/bin/env ruby
############################################################
###
##  File:  test_IseScenario.rb
##  Desc:  unit tests for the IseScenario library
#

require 'rubygems'
require 'pp'

require 'IseScenario'
require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

###################################
## fake classes used during testing

class Base
  @@sub_classes = []
  def initialize
    @my_callback = nil
  end
  def self.inherited(subclass)
    @@sub_classes << subclass
  end
  def self.sub_classes
    return @@sub_classes
  end
  def self.subscribe(something)
    puts "Subscribed to #{self.to_s.to_sym}"
    puts "something: #{something.class}"
    @my_callback = something
  end
end

class OneAndA < Base
end

class TwoAndA < Base
end

class ThreeForTheMoney < Base
end

class FourLetsGo < Base
end


#############################################
## Test class for the IseScenario library

class TestIseScenario < Test::Unit::TestCase
  
  def setup
    $debug = false
  end
  
  def teardown
  end

  #############
  def test_desc
    s = IseScenario.new "My Test"
    assert_equal "My Test", s.desc
    s.desc = "Another Test"
    assert_equal "Another Test", s.desc
  end
  
  #############
  def test_step
    s=IseScenario.new "Step test"
    assert_equal 0.1, s.step, "Step default"
    s.step = 1.0
    assert_equal 1.0, s.step, "Step changed"
    
    assert_equal 0.0, s.now, "Default now"
    
    s.at(:next) do
      s.remark "hello"
    end
      
    assert_equal 1.0, s.now, "Time has advanced by one step"
    
    s.at(:next) do
      s.remark "hello again"
    end
    
    assert_equal 2.0, s.now, "Time has advanced by another step"
    
  end
  
  ###########
  def test_at
    s=IseScenario.new "testing the at method"
    assert s.tasks.empty?
    
    s.at(1.0) do
      puts "a task"
    end
    
    assert_equal 1, s.tasks.length, "only one task-time in the queue"
    assert s.tasks.include?(1.0), "An entry for 1.0 exists"
    assert s.tasks[1.0].length == 1, "only 1 task for this time"
    assert_kind_of Proc, s.tasks[1.0][0], "its a Proc queue"
    
    s.at(1.0) do
      puts "a second task"
    end
    
    assert_equal 1, s.tasks.length, "only one task-time in the queue"
    assert s.tasks.include?(1.0), "An entry for 1.0 exists"
    assert s.tasks[1.0].length == 2, "only 2 tasks for this time"
    assert_kind_of Proc, s.tasks[1.0][0], "its a Proc queue"
    assert_kind_of Proc, s.tasks[1.0][1], "its still a Proc queue"
    
    
    s.at(99.9) do
      puts "a different task for a different time"
    end
    
    assert_equal 2, s.tasks.length, "only two task-times in the queue"
    assert s.tasks.include?(99.9), "An entry for 99.9 exists"
    assert s.tasks[99.9].length == 1, "only 1 task for this time"
    assert_kind_of Proc, s.tasks[99.9][0], "its a Proc queue"
    
  end
  
  
  def test_every_1
  
    puts "testing the every method"
  
    s=IseScenario.new "Testing periodic_tasks"

    assert_equal 0.1, s.step, "Default step size"
    assert_equal 0.1, IseScenario.runtime_step, "Default runtime_step"

    assert s.periodic_tasks.empty?
    
    s.every(15.5) do
      puts "==== something ===="
      $worked = true
    end
    
    assert s.periodic_tasks.length == 1, "There is one periodic task in the queue"
    
    assert s.periodic_tasks[0].length == 4, "There are 4 data items for each pTask"
    assert_kind_of Range, s.periodic_tasks[0][0], "First element is a Range"
    assert_equal 0.0, s.periodic_tasks[0][1], "count-down"
    assert_equal 15.5, s.periodic_tasks[0][2], "period"
    assert_kind_of Proc, s.periodic_tasks[0][3], "do_something"
    

  end

  ##########################################################
  def test_every_2

    puts "testing the every method"

    s=IseScenario.new "Testing periodic_tasks"
    s.step = 1.0
    IseScenario.runtime_step = 1.0

    assert_equal 1.0, s.step, "Explicit step size"
    assert_equal 1.0, IseScenario.runtime_step, "Explicit runtime_step"

    assert s.periodic_tasks.empty?

    s.every(1.0, 10.0, 12.0) do
      puts "=============== something else ======================="
      $worked = true
    end
    
    assert s.periodic_tasks.length == 1, "There is one periodic tasks in the queue"
    
    assert s.periodic_tasks[0].length == 4, "There are 4 data items for each pTask"
    assert_kind_of Range, s.periodic_tasks[0][0], "First element is a Range"

    assert_equal (10.0..12.0), s.periodic_tasks[0][0], "Range is as expected"

    assert_equal 0.0, s.periodic_tasks[0][1], "count-down"
    assert_equal 1.0, s.periodic_tasks[0][2], "period"
    assert_kind_of Proc, s.periodic_tasks[0][3], "do_something"
    
    s.step=1
    
    (0.0 .. 17.0).step(1.0) do |xxx|
      puts "calling s.run(#{xxx})"
      $worked = false
      xxx_before = xxx
      s.run(xxx)

      assert_equal xxx, xxx_before, "No side effects"

      
      if xxx < 10.0
        puts xxx
        assert_equal false, $worked, "periodic block did not execute"
      end
      
      if (10.0 .. 12.0).include? xxx
        assert $worked, "periodic block executed at time #{xxx}"
      end
      
      if (13.0 .. 14.0).include? xxx
        assert_equal false, $worked, "periodic block did not execute"      
      end
            
      if xxx > 15.0 == xxx
        assert_equal false, $worked, "periodic block did not execute"      
      end
      
    end
    
  end
  
  #####################
  def test_advance_time
    s=IseScenario.new "Test events"
    s.step = 1.0
    
    $test_value = 0
    
    assert_equal 0.0, s.now
    
    s.at(:next) do
      $test_value += 1
    end
    
    assert_equal 1.0, s.now
    
    s.at(:next) do
      $test_value += 10
    end
    
    assert_equal 2.0, s.now
    
    s.at(:next) do
      $test_value += 100
    end
    
    assert_equal 3.0, s.now
    assert_equal 1.0, s.step
    
    s.reset
    
    assert_equal 0.0, s.now
    assert_equal 0.1, s.step
    
    100.times do
      s.advance_time
    end
    
    assert_in_delta 10.0, s.now, 0.0000000000001, "after 100 iterations of 0.1 steps"
    assert_equal 111, $test_value, "All three blocks were executed exactly once"
    
    
  end
  
  #################################
  def test_setting_unsetting_events
    s=IseScenario.new "Test events"
    s.set :hello
    assert s.test(:hello), "Hello set"
    s.unset :hello
    assert_equal false, s.test(:hello), "Hello is unset"
    s.assert :fan_boy
    assert s.test(:fan_boy), "assert is an alias of set"
    s.retract :fan_boy
    assert_equal false, s.test(:fan_boy), "retract is an alias of unset"
    s.assert :fan_boy
    assert s.test(:fan_boy), "assert is an alias of set"
    s.rescend :fan_boy
    assert_equal false, s.test(:fan_boy), "rescend is an alias of unset"
    s.assert :fan_boy
    assert_equal s.set?(:fan_boy), s.test(:fan_boy), "set? is an alias of test"
    s.clear :fan_boy
    assert_equal false, s.test(:fan_boy), "clear is an alias of unset"
  end
  
  ###########
  def test_on
    s=IseScenario.new "Test events"
    IseScenario.events={}
    IseScenario.event_values={}
    
    $test_value = nil
    
    assert IseScenario.events.empty?, "no events have been defined"
    assert IseScenario.event_values.empty?, "no values have been recorded"
    
    assert_kind_of Hash, IseScenario.events
    assert_kind_of Hash, IseScenario.event_values
    
    s.on(:hello) do
      $test_value = true
    end
    
    assert_nil $test_value, "The block was not executed"
    
    assert_equal 1, IseScenario.events.length, "one events has been defined"
    assert_equal 1, IseScenario.event_values.length, "one event value has been recorded"

    assert IseScenario.events.include?(:hello), ":hello is the event"
    assert IseScenario.event_values.include?(:hello), ":hello has a value"
    assert_nil IseScenario.event_values[:hello], "initial value is nil, meaning unknown"
    
    assert_kind_of Array, IseScenario.events[:hello], "Its an array"
    assert_equal 1, IseScenario.events[:hello].length, "The array has only one entry"
    assert_kind_of Array, IseScenario.events[:hello][0], "Its an array of arrays"
    assert_kind_of TrueClass, IseScenario.events[:hello][0][0], "Its an entry for when the event is true"
    assert_kind_of Proc, IseScenario.events[:hello][0][1], "Its a Proc"
    
    s.on(:hello, false) do
      $test_value = false
    end
    
    assert_nil $test_value, "still nil means the 2nd block was not executed"
   
    assert_equal 2, IseScenario.events[:hello].length, "The array has only one entry"
    assert_kind_of Array, IseScenario.events[:hello][1], "the second entry is also an array of arrays"
    assert_kind_of FalseClass, IseScenario.events[:hello][1][0], "Its an entry for when the event is false"
    assert_kind_of Proc, IseScenario.events[:hello][1][1], "Its also a Proc"
   
    s.set :hello
    assert IseScenario.event_values[:hello], "Lhello is true"
    assert $test_value, "the true block was executed"
    
    s.unset :hello
    assert_equal false, IseScenario.event_values[:hello], "hello is false"
    assert_equal false, $test_value, "the false block was executed"
    
    s.toggle :hello
    assert IseScenario.event_values[:hello], "toggle makes :hello true again"
    assert $test_value, "the true block was executed again"
    
    s.toggle :hello
    assert_equal false, IseScenario.event_values[:hello], "and toggle makes it false again"
    assert_equal false, $test_value, "the false block was executed again"


    rtn_code = s.on(:bad_class, 123.456) do
      puts "bad class"
    end

    assert rtn_code.nil?, "the class was not TrueClass or FalseClass"


    rtn_code = s.on(:good_class, true) do
      puts "good class"
    end

    assert_equal 'Hash', rtn_code.class.to_s

  end


  
  ##################################
  def test_message_subscription_moch
    s=IseScenario.new "Test Moch message receipt"
    
    $debug = true
    $verbose = true
    
    $test_value = 0
    
    Base.sub_classes.each do |sc|
      s.on sc.to_s.to_sym do
        $test_value += 1
      end
    end
    
    assert_equal 4, Base.sub_classes.length, "The moch class has only 4 sub classes"
    assert_equal 4, IseScenario.events.length, "there are four moch messages"
    assert_equal 4, IseScenario.event_values.length, "there are four moch messages"
    assert_equal 0, $test_value, "no block has been executed yet"
    
    IseScenario.events.each_key do |event|
      assert_equal 1, IseScenario.events[event].length, "only 1 block per message"
      assert_kind_of TrueClass, IseScenario.events[event][0][0], "All blocks are to be executed when event is true"
    end
    
    IseScenario.events.each_key do |event|
      assert_nil IseScenario.event_values[event], "Have not received any message yet so all msg events are nil"
    end
    
    Base.sub_classes.each do |sc|
      s.set sc.to_s.to_sym 
    end
        
    assert_equal 4, $test_value, "All Proc blocks have executed"
    
    s.set :OneAndA
    s.set :TwoAndA
    s.set :ThreeForTheMoney
    s.set :FourLetsGo
    
    assert_equal 8, $test_value, "All Proc blocks have executed again"

  end
  
  ##################
  def test_subscribe
    s=IseScenario.new "testing the subscribe infrastructure"
    
    $testing = true
    $debug   = true

    IseScenario.clear_messages   ## ensure no side effects from prior test cases
    
    assert IseScenario.messages.empty?, "no messages have been subscribed"
    
    IseScenario.subscribe(FourLetsGo)
    
    assert_equal 1, IseScenario.messages.length, "one message has been subscribed"
    
    assert IseScenario.messages.include? :FourLetsGo
    assert_kind_of Array, IseScenario.messages[:FourLetsGo]
    assert_equal 2, IseScenario.messages[:FourLetsGo].length
    assert_nil IseScenario.messages[:FourLetsGo][0]
    assert_nil IseScenario.messages[:FourLetsGo][1]
  
  end

  ###############################################
  def test_receive_message
    s=IseScenario.new "testing the subscribe infrastructure"

    $testing = true
    $debug   = true

    a_header = "Header"
    a_message = FourLetsGo.new

    $four_lets_go = false

    s.on(:FourLetsGo) do
      $four_lets_go = true
    end

    assert_equal false, $four_lets_go, "no side effects"

    assert_nil s.test(:FourLetsGo), "no message received yet"

    IseScenario.receive_message(a_header, a_message)

    assert s.test(:FourLetsGo), "Received a new message"
    assert $four_lets_go, "callback block was executed"
    
  end

  #####################
  def test_list
    s=IseScenario.new "testing"
    s.list
    s.remark "don't care"
    assert true, "Don't care what the list output looks like"
  end

  #####################
  def test_remark
    s=IseScenario.new "testing"
    s.remark "don't care"
    assert true, "Don't care what the remark output looks like"
  end

  ################################
  def test_instances
    all_instances = IseScenario.instances
    assert_equal 'Array', all_instances.class.to_s, "@@instances/@@kids is an array"
  end
  
  
  #################
  def test_messages
    all_messages = IseScenario.messages
    assert_equal 'Hash', all_messages.class.to_s, "@@messages is a hash"
  end

end ## end of class TestIseScenario

## end of file: test_scenario.rb
################################

