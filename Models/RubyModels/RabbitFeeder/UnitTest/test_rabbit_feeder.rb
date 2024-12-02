#!/usr/bin/env ruby
#########################################################
###
##  File:  test_rabbit_feeder.rb
##  Desc:  Run some tests on the RabbitFeeder module
#

puts
puts "#"*65
puts "## Testing the rabbit_feeder IseRubyModel"
puts

$verbose, $debug = true, true

require 'rabbit_feeder'

# Put your test code here

puts "test failed on rabbit_feeder"
exit -1     # means the test has failed
#exit 0      # means the test was successfull

