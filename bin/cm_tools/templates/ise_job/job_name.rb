#!/usr/bin/env ruby
###################################################
###
##  File:  <%= job_name %>_job.rb
##  Desc:  <%= job_desc %>
#

require 'IseJCL'

job_name = "<%= job_name %>"
job_desc = "<%= job_desc %>"

if Job.find_by_name(job_name)
  the_job = IseJob.replace(job_name, job_desc)
else
  the_job = IseJob.new(job_name, job_desc)
end

the_job.basepath   = $ISE_ROOT
the_job.input_dir  = "input"
the_job.output_dir = "output/#{job_name}"

######################################################
## Add models to this IseJob


=begin
This comment block contains examples of some common IseModels that
you may want as part of your IseJob.



##########################################################
controller = IseModel.new(
    "FramedController",
    "Job Framed-based Controller",
    "i386-linux",
    "FramedController"
)
# .........................vvvvvv specifies the number of monte carlo cases to run
#                          vvvvvv  vvvvvvvvvvvvvv You can also specify the maximun number of frames to run 
controller.cmd_line_param="--MC=1  --max_frame=60"
the_job.add(controller)



##########################################################
message_logger = IseModel.new(
  "ruby_message_logger",
  "Ruby-based generic message logger",
  "any",
  "ruby_message_logger"
)

# ................................. vvvvvvv replace all of these message names with your own vvvvvvvvvvvvvvvv
message_logger.cmd_line_param = "-m ThreatEvaluation,LauncherBid,InterceptorHitTarget,InterceptorMissedTarget"

the_job.add(message_logger)


=end




the_job.register


