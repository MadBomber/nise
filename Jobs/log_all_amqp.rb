#!/usr/bin/env ruby
###################################################
###
##  File:  log_all_amqp.rb
##  Desc:  Log all AMQP Messages
#

require 'IseJCL'

job_name = "log_all_amqp"
job_desc = "Ruby Message Logger for all AMQP Messages"

the_job = IseJob.init(job_name, job_desc)

the_job.basepath   = $ISE_ROOT
the_job.input_dir  = "input"
the_job.output_dir = "output/#{job_name}"

the_job.router     = :both


# List of IseMessages to log ...
=begin
log_these = %w{
  ConnectAllDcs
  ConnectDc
  ControllableState
  DcConnected
  DcControlMessage
  DcDisconnected
  DeviceState
  DisconnectAllDcs
  DisconnectDc
  HmiControlMessage
  HmiReinitializeModel
  OptControlMessage
  ResetDrcChecks
  SeedAllDrcStates
  ShutdownMccEvent
  StartupMccEvent
  UpdateDeviceParameters
}
=end

##########################################################
ruby_message_logger = IseModel.new(
  "ruby_message_logger",
  "Ruby-based generic message logger",
  "ruby",
  "ruby_message_logger"
)

ruby_message_logger.count           = 1
ruby_message_logger.router          = :both
ruby_message_logger.cmd_line_param  = "--amqp --all"
the_job.add(ruby_message_logger)


##########################################################

the_job.register
the_job.show

