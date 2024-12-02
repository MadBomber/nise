#!/usr/bin/env ruby
###################################################
###
##  File:  test_file_transfer_job.rb
##  Desc:  Testing the file transfer capability of an IseMessage
##         using the :cstring and :p4string data types
#

require 'IseJCL'

job_name = "file_transfer_test"

if Job.find_by_name(job_name)
  the_job = IseJob.replace(job_name)
else
  the_job = IseJob.new(job_name, "Test the ability of an IseMessage to transfer a file")
end

the_job.basepath   = $ISE_ROOT
the_job.input_dir  = "input"
the_job.output_dir = "output/#{job_name}"


##########################################################
controller = IseModel.new(
    "FramedController",
    "Job Frame-based Controller",
    "x86_64-linux",
    "FramedController"
)

controller.cmd_line_param="-m1"
the_job.add(controller)

##########################################################
scenario_driver_model = IseModel.new(
  "scenario_driver",
  "Ruby-based simple scenario driver",
  "any",
  "scenario_driver"
)
scenario_driver_model.count           = 1
scenario_driver_model.cmd_line_param  = [ "--rate 1.0 --scenario test_file_transfer_scenario"]
the_job.add(scenario_driver_model)


##########################################################
ruby_message_logger = IseModel.new(
  "ruby_message_logger",
  "Ruby-based generic message logger",
  "any",
  "ruby_message_logger"
)

ruby_message_logger.cmd_line_param = "-m FileTransferRequest,FileTransfer,EndCase,EndRun,EndRunComplete,EndCaseComplete"
the_job.add(ruby_message_logger)



the_job.register


