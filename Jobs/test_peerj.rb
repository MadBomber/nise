#!/usr/bin/env ruby
###################################################
###
##  File:  test_peerj.rb
##  Desc:  Testing the launching of a Java model using the peerj script
#

require 'IseJCL'

job_name = "test_peerj"
job_desc = "Test the ability of peerj to execute a Java model"

the_job = IseJob.init(job_name, job_desc)


the_job.basepath   = $ISE_ROOT
the_job.input_dir  = "input"
the_job.output_dir = "output/#{job_name}"


##########################################################
## This is a stand-alone Java program encapsulated as
## as a JAR file.  The system environment variable CLASSPATH
## must contain thie full absolute path to the JAR file.
## The speculation is that all of its dependencies must also
## be located within the CLASSPATH

the_model = IseModel.new(
    "HelloWorld",
    "A simple java program that prints stuff to stdout",
    "java",
    "HelloWorld"
)

the_model.cmd_line_param=""
the_job.add(the_model)


the_job.register


