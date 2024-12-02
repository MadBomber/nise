#############################################################################
###
##  Name:   test_scenario.rb
##
##  Desc:   A test scenario for the ruby-based simple scenario driver test
##

puts "Entering: #{File.basename(__FILE__)}" if $debug

######################################
## require all the messages to be sent

require 'TrkRadarOnCmd'
require 'LaunchRequest'
require 'LaunchCmd'
require 'EndEngagement'
require 'EndRun'


############################################################
## instantiate a new scenario with a single line description

s = IseScenario.new "Testing the ScenarioDriverModel"

puts "DEBUG:  #{__LINE__}"

s.step = 1.0    ## time step in decimal seconds

s.at(0.0) { s.remark "Let the testing begin" }

s.at(1.0)   { s.remark "One second" }
s.at(:next) { s.remark "two seconds" }
s.at(:next) { s.remark "three seconds" }

s.at(0.5)   { s.remark "sequence does not have to be in order" }
s.at(:next) { s.remark "1.5 seconds" }

s.step = 5.0

s.at(:next) do
  a_message = TrkRadarOnCmd.new
  a_message.time_   = $sim_time.offset
  a_message.on_     = 1           ## true = 1
  a_message.unitID_ = 1
  a_message.publish
  s.remark "== Published TrkRadarOnCmd Message =="
end

s.at(:next) do
  a_message = LaunchRequest.new
  a_message.time_   = $sim_time.offset
  a_message.unitID_ = 1
  a_message.publish
  s.remark "== Published LaunchRequest Message =="
end


s.step = 1.0

s.at(:next) do
  a_message = LaunchCmd.new
  a_message.time_   = $sim_time.offset
  a_message.unitID_ = 1
  a_message.publish
  s.remark "== Published LaunchCmd Message =="
end


s.at(:next) do
  EndEngagement.new.publish
  s.remark "== Published EndEngagement Message =="
end


s.at(s.now + rand(5)) do
  EndRun.new.publish
  s.remark "== Published EndRun Message =="
end


s.list  if $debug


## The End
##################################################################

