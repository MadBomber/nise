#!/usr/bin/env ruby
#############################################################################
###
##  Name:   FramedTater.rb
##  Desc:   This is a hot patato example that inherits from the SamsonModel
#

require 'IseJCL'

############################################################################
## Define a new IseJob
## There are two requred parameters: the name of the job and its description

the_job = IseJob.init(  "FramedTater",
                        "Framed Hot Potato ISE test example")

the_job.basepath   = $ISE_ROOT      # basepath is defaulted to the $ISE_ROOT
the_job.input_dir  = "input"        # default input  directory for this IseJob
the_job.output_dir = "output/tater" # default output directory for this IseJob


##########################################################
the_model = IseModel.new(
    "FramedTater",                      # name of the IseModel
    "Hot Potato Message Passing Test?", # short description
    "x86_64-linux",                       # the platform for which the IseModel was built
    "FramedTater"                       # the location where the IseModel can be found
)

the_model.count           = 3
the_model.cmd_line_param  = "-n#{the_model.count} -M5"

the_job.add(the_model)

##########################################################
controller = IseModel.new(
    "FramedController",
    "Job Frame Controller",
    "x86_64-linux",
    "FramedController"
)
controller.cmd_line_param = "-m1"

the_job.add(controller)

the_job.register  # all desired IseModels have been added, so
                  # now register the IseJob into the IseDatabase

__END__

puts
puts "================================================"
puts "IseJob Configuration as defined in #{__FILE__}"
puts
the_job.show
puts

puts "================================================"
list_all_jobs

puts "================================================"
puts "IseJob as defined in the IseDatabase"
puts
list_job(the_job)

