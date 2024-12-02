#!/usr/bin/env ruby
#############################################################################
###
##  Name:   sd_test_job.rb
##
##  Desc:   an IseJob configuration file for a simple scenario driver test
##

######################################################
## All configuration files start with the same command

require 'IseJCL'    ## This line identifies this file as an ISE
                    ## Job Control Language file.

############################################################################
## Define a new IseJob
## There are two requred parameters: the name of the job and its description


#samson_3on3 = IseJob.delete(    # Note use of parens to encolse the parameters
#    "samson_3on3")              # Some short meaningful name

if Job.find_by_name("sd_test")

  ## replace is the same thing as a delete followed by a new
  the_job = IseJob.replace(       # Note use of parens to enclose the parameters
      "sd_test") # Some short meaningful name

else

  the_job = IseJob.new(                           # Note use of parens to encolse the parameters
      "sd_test",                 # Some short meaningful name
      "Scenario Driver Test")  # Single line description,

end

# Establishes an absolute basepath for all components for this job
# optional; if present, MUST be absolute to an existing directory
the_job.basepath   = $ISE_ROOT


# Establish Defaults for the input and output directories to be used by this IseJob
# If relative paths, the basepath, if supplied, will be pre-pended.
the_job.input_dir  = "input"              # default input  directory for this IseJob
the_job.output_dir = "output/sd_test_job" # default output directory for this IseJob


# Now define some IseModels to be part of this IseJob....



##########################################################
controller = IseModel.new(
    "TimedController",
    "Job Timed Controller",
    "i386-linux",
    "TimedController"
)
controller.cmd_line_param="-m1000 -f10"
the_job.add(controller)


##########################################################
scenario_driver_model = IseModel.new(
  "scenario_driver",
  "Ruby-based simple scenario driver",
  "any",
  "scenario_driver"
)

scenario_driver_model.cmd_line_param = "--rate 0.1 --scenario test_scenario"

the_job.add(scenario_driver_model)

##########################################################
ruby_message_logger = IseModel.new(
  "ruby_message_logger",
  "Ruby-based generic message logger",
  "any",
  "ruby_message_logger"
)

ruby_message_logger.cmd_line_param = "-m LaunchCmd,LaunchRequest,TrkRadarOnCmd,EndEngagement,EndRun"

the_job.add(ruby_message_logger)



the_job.register             # all desired IseModels have been added, so
                                 # now register the IseJob into the IseDatabase
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



## The End
##################################################################

