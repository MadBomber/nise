#!/usr/bin/env ruby
#############################################################################
###
##  Name:   peerrb_test_isejob.rb
##
##  Desc:   Creates an IseJob specifically to test the peerrb
##

require 'IseJCL'


peerrb_test = IseJob.init "peerrb_test", "Testing the peerrb with multiple IseRouters"

peerrb_test.router     = :both
peerrb_test.basepath   = $ISE_ROOT
peerrb_test.input_dir  = "input/peerrb_test"
peerrb_test.output_dir = "output/peerrb_test"


##########################################################
controller = IseModel.new(
     "FramedController",
    "Steps the models through the frames",
    "x86_64-linux",
    "FramedController"
)
controller.router         = :dispatcher
controller.cmd_line_param = "--MC=1 --max_frame=12"  # --start_frame_hz=1.0 --advance_time"

peerrb_test.add(controller)



##########################################################
example_model = IseModel.new(
    "example_ruby_model",                           # name of the IseModel
    "A basic example IseModel implemented in Ruby", # short description
    "ruby",                                         # the platform for which the IseModel was built
    "example_ruby_model"                            # the location where the IseModel can be found
)

example_model.router    = :both

example_model.basepath  = "Models/RubyModels/ExampleRubyModel"

example_model.count           = 3
example_model.cmd_line_param  = ["--parm1",         "--parm2",         "--parm3"]
example_model.inputs          = ["input_file1.txt", "input_file2.txt", "input_file3.txt"]

peerrb_test.add(example_model)            # add the IseModel to an IseJob






##########################################################
feed_the_bunny = IseModel.new(
    "rabbit_feeder",                           # name of the IseModel
    "Provides a gateway between IseMessages and an AMQP/RabbitMQ Server", # short description
    "ruby",                                    # the platform for which the IseModel was built
    "rabbit_feeder"                            # the location where the IseModel can be found
)

feed_the_bunny.router           = :both
feed_the_bunny.count            = 1

feed_these_messages = %w(
  RunConfiguration
)

feed_the_bunny.cmd_line_param = "-m #{feed_these_messages.join(',')}"


peerrb_test.add(feed_the_bunny)            # add the IseModel to an IseJob


####################################################################################

peerrb_test.register             # all desired IseModels have been added, so
                                 # now register the IseJob into the IseDatabase
puts
puts "="*60
puts "IseJob Configuration as defined in #{__FILE__}"
puts
peerrb_test.show
puts

puts "="*60
list_all_jobs

puts "="*60
puts "IseJob as defined in the IseDatabase"
puts
list_job(peerrb_test)

=begin
puts "="*60
puts "IseJob Instance Variables:"
puts peerrb_test.instance_variables
puts
puts "IseModel Instance Variables:"
puts example_model.instance_variables
=end

