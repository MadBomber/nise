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

if Job.find_by_name("samson_3on3")

  ## replace is the same thing as a delete followed by a new
  samson_3on3 = IseJob.replace(   # Note use of parens to enclose the parameters
      "samson_3on3")              # Some short meaningful name

else

  samson_3on3 = IseJob.new(       # Note use of parens to encolse the parameters
      "samson_3on3",              # Some short meaningful name
      "SamsonSimulation 3 on 3")  # Single line description,

end

# Establishes an absolute basepath for all components for this job
# optional; if present, MUST be absolute to an existing directory
samson_3on3.basepath   = $ISE_ROOT


# Establish Defaults for the input and output directories to be used by this IseJob
# If relative paths, the basepath, if supplied, will be pre-pended.
samson_3on3.input_dir  = "input"              # default input  directory for this IseJob
samson_3on3.output_dir = "output/samson_3on3" # default output directory for this IseJob


# Now define some IseModels to be part of this IseJob....

##########################################################
launcher_model = IseModel.new(
    "Launcher",
    "Simple CartoonModel of a Launcher",
    "x86_64-linux",
    "Launcher"
)

launcher_model.basepath   = $ISE_ROOT  # a model can also have a basepath, it may be either relative or absolute

samson_3on3.add(launcher_model)

##########################################################
missile_model = IseModel.new(
    "Missile",
    "Simple CartoonModel of a Missile -- _aka_ Interceptor",
    "x86_64-linux",
    "Missile"
)
missile_model.count=3           # specify the number of instances for this IseModel within the IseJob

samson_3on3.add(missile_model)

##########################################################
samsonappcontroller_model = IseModel.new(
    "FramedController",
    "Steps the models through the frames",
    "x86_64-linux",
    "FramedController"
)
#samsonappcontroller_model.cmd_line_param="-A -F10"
#samsonappcontroller_model.cmd_line_param="-F10"
samsonappcontroller_model.cmd_line_param="--MC=2"

samson_3on3.add(samsonappcontroller_model)

##########################################################
sr_model = IseModel.new(
    "SearchRadar",
    "Simple CartoonModel of a Search Radar",
    "x86_64-linux",
    "Sr"
)

samson_3on3.add(sr_model)

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

#target_model.drones         = ["pcig29", "pcig30", "pcig31"]  # and different specified IseDrones


samson_3on3.add(target_model)

##########################################################
toc_model = IseModel.new(
    "TacticalOperationsCenter",
    "Simple CartoonModel of a Tactical Operations Center",
    "x86_64-linux",
    "TOC"
)

samson_3on3.add(toc_model)

##########################################################
trkradar_model = IseModel.new(
    "TrackingRadar",
    "Simple CartoonModel of a Tracking Radar",
    "x86_64-linux",
    "TrkRadar"
)

samson_3on3.add(trkradar_model)

##########################################################
vatlogdata_model = IseModel.new(
    "VAT Data Logger",
    "(depreciated) Legacy tool to create input files to a 3d visualization tool called VAT",
    "x86_64-linux",
    "VatLogData"
)

samson_3on3.add(vatlogdata_model)

##########################################################
dblogger_model = IseModel.new(
    "Database Logger",
    "Message Traffic Logger to the IseDatabase",
    "x86_64-linux",
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


=begin
# TODO: Convert to unit test cases
#######################################################
## Define a different IseJob without the DBLogger Model

if Job.find_by_name("Samson3on3_No_DBLogger")

  ## replace is the same thing as a delete followed by a new
  samson_3on3_without_dblogger = IseJob.replace(   # Note use of parens to enclose the parameters
      "Samson3on3_No_DBLogger")                    # Some short meaningful name
  list_job("Samson3on3_No_DBLogger")
  
else

  samson_3on3_without_dblogger      = samson_3on3.clone          # make an exact copy of another IseJob
  samson_3on3_without_dblogger.name = "Samson3on3_No_DBLogger"
  samson_3on3_without_dblogger.desc = "SamsonSimulation 3 on 3 without the DBLogger Model"

  samson_3on3_without_dblogger.remove(dblogger_model)            # remove an IseModel from an IseJob
  samson_3on3_without_dblogger.show                              # show the details on an IseJob

end

samson_3on3_without_dblogger.register


#######################################################
## Define a different IseJob without the DBLogger and
## the VATlogger models


if Job.find_by_name("Samson3on3_No_Loggers")

  ## replace is the same thing as a delete followed by a new
  samson_3on3_without_loggers = IseJob.replace(   # Note use of parens to enclose the parameters
      "Samson3on3_No_Loggers")                    # Some short meaningful name
  list_job("Samson3on3_No_Loggers")
else

  samson_3on3_without_loggers      = samson_3on3_without_dblogger.clone
  samson_3on3_without_loggers.name = "Samson3on3_No_Loggers"
  samson_3on3_without_loggers.desc = "SamsonSimulation 3 on 3 without the DBLogger and VATlogData Models"

  samson_3on3_without_loggers.remove(vatlogdata_model)
  samson_3on3_without_loggers.show
  
end

samson_3on3_without_loggers.register



#######################################################
## Define a different IseJob
## SamsonSimulation 40 on 40

samson_40_on_40      = samson_3on3.clone
samson_40_on_40.name = "Samson_40_on_40"
samson_40_on_40.desc = "SamsonSimulation 40 on 40"

launcher_model.count = 5
trkradar_model.count = 5
target_model.count   = 40
missile_model.count  = 40

# An IseJCL file is a full Ruby script environment.
# This is an example of how to specify uniformly named
# configuration files for each instance of the target_model
target_model.inputs = []                         # define and empty array
40.times do |x|                                  # loop 40 times, 'x' will be 1..40
    target_model.inputs.push("target#{x+1}.cfg") # push a new filename into the array using value of 'x'
end                                              # as part of the file name

samson_40_on_40.register

samson_40_on_40.show

puts "==========================================================="
list_all_jobs    # lists the ids, names and descriptions of all IseJobs defined in the IseDatabase
puts "==========================================================="
list_job(1)      # list the details for IseJob #1
puts "==========================================================="
list_job(2)      # list the details for IseJob #2
puts "==========================================================="
list_job(3)      # list the details for IseJob #3
puts "==========================================================="
list_job("Samson3on3_No_Loggers")     # can also list an IseJob using its name
puts "==========================================================="
list_job(samson_3on3)                 # can also list an IseJob by its symbol
puts "==========================================================="
list_job(4)
puts "==========================================================="
list_job("xyzzy")
puts "==========================================================="
xyzzy_as_symbol = Hash.new
list_job(xyzzy_as_symbol)
puts "==========================================================="
IseJob.delete(samson_40_on_40)
puts "==========================================================="
IseJob.delete(samson_3on3_without_loggers)
puts "==========================================================="
IseJob.delete(samson_3on3_without_dblogger)

=end
## The End
##################################################################

