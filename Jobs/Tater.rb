#!/usr/bin/env ruby
#############################################################################
###
##  Name:   Tater.rb
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

if Job.find_by_name("Tater")

  ## replace is the same thing as a delete followed by a new
  the_job = IseJob.replace(   # Note use of parens to enclose the parameters
      "Tater")              # Some short meaningful name

else

  the_job = IseJob.new(       # Note use of parens to encolse the parameters
      "Tater",              # Some short meaningful name
      "Hot Potato ISE test example")  # Single line description,

end

# Establishes an absolute basepath for all components for this job
# optional; if present, MUST be absolute to an existing directory
the_job.basepath   = $ISE_ROOT


# Establish Defaults for the input and output directories to be used by this IseJob
# If relative paths, the basepath, if supplied, will be pre-pended.
the_job.input_dir  = "input"              # default input  directory for this IseJob
the_job.output_dir = "output/tater" # default output directory for this IseJob


# Now define some IseModels to be part of this IseJob....

##########################################################
the_model = IseModel.new(
    "Tater",                              # name of the IseModel
    "Hot Potato Message Passing Test?",   # short description
    "x86_64-linux",              # the platform for which the IseModel was built
    "Tater"                     # the location where the IseModel can be found
)

the_model.count=20           # specify the number of instances for this IseModel within the IseJob
#the_model.cmd_line_param="-n#{the_model.count} -M50 -P200 -t"  # command line parameters to be used by the IseModel
the_model.cmd_line_param="-n#{the_model.count} -M5 -P200"  # command line parameters to be used by the IseModel

the_job.add(the_model)            # add the IseModel to an IseJob

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

