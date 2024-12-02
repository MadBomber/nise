#!/usr/bin/env ruby
#############################################################################
###
##  Name:   win_SamsonSimulation_3on3.rb
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
#    "win_samson_3on3")              # Some short meaningful name

if Job.find_by_name("win_samson_3on3")

  ## replace is the same thing as a delete followed by a new
  samson_3on3 = IseJob.replace(       # Note use of parens to enclose the parameters
      "win_samson_3on3")              # Some short meaningful name

else

  samson_3on3 = IseJob.new(                      # Note use of parens to encolse the parameters
      "win_samson_3on3",                         # Some short meaningful name
      "SamsonSimulation 3 on 3 for MS Windows")  # Single line description,

end

# Establishes an absolute basepath for all components for this job
# optional; if present, MUST be absolute to an existing directory
samson_3on3.basepath   = $ISE_ROOT


# Establish Defaults for the input and output directories to be used by this IseJob
# If relative paths, the basepath, if supplied, will be pre-pended.
samson_3on3.input_dir  = "input"                  # default input  directory for this IseJob
samson_3on3.output_dir = "output/win_samson_3on3" # default output directory for this IseJob


# Now define some IseModels to be part of this IseJob....

##########################################################
executive_model = IseModel.new(
    "win_Executive",                        # name of the IseModel
    "What does the Executive really do?",   # short description
    "i386-mswin32",                         # the platform for which the IseModel was built
    "Executive"                             # the location where the IseModel can be found
)
executive_model.cmd_line_param="-n3"        # command line parameters to be used by the IseModel

samson_3on3.add(executive_model)            # add the IseModel to an IseJob

##########################################################
launcher_model = IseModel.new(
    "win_Launcher",
    "Simple CartoonModel of a Launcher",
    "i386-mswin32",
    "Launcher"
)

launcher_model.basepath   = $ISE_ROOT  # a model can also have a basepath, it may be either relative or absolute

samson_3on3.add(launcher_model)

##########################################################
missile_model = IseModel.new(
    "win_Missile",
    "Simple CartoonModel of a Missile -- _aka_ Interceptor",
    "i386-mswin32",
    "Missile"
)
missile_model.count=3           # specify the number of instances for this IseModel within the IseJob

samson_3on3.add(missile_model)

##########################################################
samsonappcontroller_model = IseModel.new(
    "win_FramedController",
    "Steps the models through the frames",
    "i386-mswin32",
    "FramedController"
)
samsonappcontroller_model.cmd_line_param="--MC=1"

samson_3on3.add(samsonappcontroller_model)

##########################################################
sr_model = IseModel.new(
    "win_SearchRadar",
    "Simple CartoonModel of a Search Radar",
    "i386-mswin32",
    "Sr"
)

samson_3on3.add(sr_model)

##########################################################
target_model = IseModel.new(
    "win_Target",
    "Simple CartoonModel of a Threat - _aka_ Target",
    "i386-mswin32",
    "TargetModel"
)
target_model.count          = 3                    # Number of targets
target_model.inputs         = ["win_Target.xml",   # Each instance of the TargetModel has the same input file
                               "win_Target.xml",
                               "win_Target.xml"]

#target_model.drones         = ["pcig29", "pcig30", "pcig31"]  # and different specified IseDrones


samson_3on3.add(target_model)

##########################################################
toc_model = IseModel.new(
    "win_TacticalOperationsCenter",
    "Simple CartoonModel of a Tactical Operations Center",
    "i386-mswin32",
    "TOC"
)

samson_3on3.add(toc_model)

##########################################################
trkradar_model = IseModel.new(
    "win_TrackingRadar",
    "Simple CartoonModel of a Tracking Radar",
    "i386-mswin32",
    "TrkRadar"
)

samson_3on3.add(trkradar_model)

##########################################################
vatlogdata_model = IseModel.new(
    "win_VAT Data Logger",
    "(depreciated) Legacy tool to create input files to a 3d visualization tool called VAT",
    "i386-mswin32",
    "VatLogData"
)

samson_3on3.add(vatlogdata_model)

##########################################################
dblogger_model = IseModel.new(
    "win_Database Logger",
    "Message Traffic Logger to the IseDatabase",
    "i386-mswin32",
    "DBLogger"
)

samson_3on3.add(dblogger_model)

samson_3on3.register             # all desired IseModels have been added, so
                                 # now register the IseJob into the IseDatabase
puts
puts "================================================"
puts "IseJob Configuration as defined in #{__FILE__}"
puts
samson_3on3.show
puts

puts "================================================"
list_all_jobs

puts "================================================"
puts "IseJob as defined in the IseDatabase"
puts
list_job(samson_3on3)



