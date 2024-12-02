#!/usr/bin/env ruby
#############################################################################
###
##  Name:   SamsonSimulation_3on3.rb
##
##  Desc:   An example of an IseJob configuration file
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

if Job.find_by_name("samson_3on3_wrl")

  ## replace is the same thing as a delete followed by a new
  samson_3on3_wrl = IseJob.replace(   # Note use of parens to enclose the parameters
      "samson_3on3_wrl")              # Some short meaningful name

else

  samson_3on3_wrl = IseJob.new(       # Note use of parens to encolse the parameters
      "samson_3on3_wrl",              # Some short meaningful name
      "SamsonSimulation 3 on 3 with Ruby Logger")  # Single line description,

end

# Establishes an absolute basepath for all components for this job
# optional; if present, MUST be absolute to an existing directory
samson_3on3_wrl.basepath   = $ISE_ROOT


# Establish Defaults for the input and output directories to be used by this IseJob
# If relative paths, the basepath, if supplied, will be pre-pended.
samson_3on3_wrl.input_dir  = "input"              # default input  directory for this IseJob
samson_3on3_wrl.output_dir = "output/samson_3on3_wrl" # default output directory for this IseJob


# Now define some IseModels to be part of this IseJob....

##########################################################
launcher_model = IseModel.new(
    "Launcher",
    "Simple CartoonModel of a Launcher",
    "x86_64-linux",
    "Launcher"
)

launcher_model.basepath   = $ISE_ROOT  # a model can also have a basepath, it may be either relative or absolute

samson_3on3_wrl.add(launcher_model)

##########################################################
missile_model = IseModel.new(
    "Missile",
    "Simple CartoonModel of a Missile -- _aka_ Interceptor",
    "x86_64-linux",
    "Missile"
)
missile_model.count=3           # specify the number of instances for this IseModel within the IseJob

samson_3on3_wrl.add(missile_model)

##########################################################
samsonappcontroller_model = IseModel.new(
    "FramedController",
    "Steps the models through the frames",
    "x86_64-linux",
    "FramedController"
)
#samsonappcontroller_model.cmd_line_param="-A -F10"
#samsonappcontroller_model.cmd_line_param="-F10"

samson_3on3_wrl.add(samsonappcontroller_model)

##########################################################
sr_model = IseModel.new(
    "SearchRadar",
    "Simple CartoonModel of a Search Radar",
    "x86_64-linux",
    "Sr"
)

samson_3on3_wrl.add(sr_model)

##########################################################
target_model = IseModel.new(
    "Target",
    "Simple CartoonModel of a Threat - _aka_ Target",
    "x86_64-linux",
    "TargetModel"
)
target_model.count          = 3                               # Number of targets
target_model.inputs         = ["Target.xml",                  # Each instance of the TargetModel has the same input file
                               "Target.xml",
                               "Target.xml"]

target_model.drones         = ["pcig29", "pcig30", "pcig31"]  # and different specified IseDrones


samson_3on3_wrl.add(target_model)

##########################################################
toc_model = IseModel.new(
    "TacticalOperationsCenter",
    "Simple CartoonModel of a Tactical Operations Center",
    "x86_64-linux",
    "TOC"
)

samson_3on3_wrl.add(toc_model)

##########################################################
trkradar_model = IseModel.new(
    "TrackingRadar",
    "Simple CartoonModel of a Tracking Radar",
    "x86_64-linux",
    "TrkRadar"
)

samson_3on3_wrl.add(trkradar_model)

##########################################################
vatlogdata_model = IseModel.new(
    "VAT_Data_Logger",
    "(depreciated) Legacy tool to create input files to a 3d visualization tool called VAT",
    "x86_64-linux",
    "VatLogData"
)

samson_3on3_wrl.add(vatlogdata_model)

##########################################################
ruby_message_logger = IseModel.new(
  "ruby_message_logger",
  "Ruby-based generic message logger",
  "any",
  "ruby_message_logger"
)

ruby_message_logger.cmd_line_param = "-m RegisterEndEngage,StartFrame,EndFrame,EndEngagement"
samson_3on3_wrl.add(ruby_message_logger)

samson_3on3_wrl.register             # all desired IseModels have been added, so
                                 # now register the IseJob into the IseDatabase
puts
puts "================================================"
puts "IseJob Configuration as defined in #{__FILE__}"
puts
samson_3on3_wrl.show
puts

puts "================================================"
list_all_jobs

puts "================================================"
puts "IseJob as defined in the IseDatabase"
puts
list_job(samson_3on3_wrl)


## The End
##################################################################

