#!/usr/bin/env ruby
#########################################################
###
##  File:  test_example_ruby_model.rb
##  Desc:  Run some tests on the ExampleRubyModel module
#

puts
puts "#"*65
puts "## Testing the example_ruby_model IseRubyModel"
puts

$verbose, $debug = true, true

require 'example_ruby_model'

# Put your test code here

puts "test failed on example_ruby_model"
exit -1     # means the test has failed
#exit 0      # means the test was successfull

