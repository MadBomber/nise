#!/usr/bin/env ruby
#########################################################
###
##  File:  test_<%= model_name %>.rb
##  Desc:  Run some tests on the <%= model_name.to_camelcase %> module
#

puts
puts "#"*65
puts "## Testing the <%= model_name %> IseRubyModel"
puts

$verbose, $debug = true, true

require '<%= model_name %>'

# Put your test code here

puts "test failed on <%= model_name %>"
exit -1     # means the test has failed
#exit 0      # means the test was successfull

