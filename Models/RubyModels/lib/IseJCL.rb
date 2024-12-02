#########################################################################
###
##  Global definitions for IseJobConfigurationLanguage (IseJCL)
##
##  IseJCL defines the Domain Specific Language (DSL) used to
##  configure and register an IseJob into the IseDatabase.  The
##  class names, attributes and methods follow a user-centric
##  naming convention which is in conflict with the current
##  implementation of the IseDatabase schema.  This DSL, therefore,
##  must bridge the gap between human readable semantic content
##  and that which is found within the IseDatabase.
##
##  The expectation is that over time, the IseDatabase schema will
##  be refactored to conform to the conventions associated with
##  Ruby on Rails as the ISE project moves from its current prototype
##  web interface to its production web interface.
##

require 'IseJCL_Utilities'	## support utilities

establish_and_validate_environment	## Ensures that the ISE environment is workable; basically
                                    ## that the setup_symbols script has been run

unless $ISE_GOOD
  puts "Please correct the problems noted."
  puts "... terminating."
  exit
end

require 'IseModel'		## defines the model from the user's point of view
require 'IseJob'		## defines the job from the user's point of view
require 'IseDatabase'	## Establish connection to the IseDatabase

###############################################################################
## Establish Global Constants from IseDatabase Tables

# Load supported platforms

all_platforms = Platform.find(:all)

$VALID_PLATFORMS         = []
$DEFAULT_PLATFORM        = all_platforms[0].name

$MODEL_PREFIX            = Hash.new      ## keys are the elements of VALID_PLATFORMS
$MODEL_SUFFIX            = Hash.new

all_platforms.length.times do |x|

  $VALID_PLATFORMS << all_platforms[x].name
  $MODEL_PREFIX[all_platforms[x].name] = all_platforms[x].lib_prefix
  $MODEL_SUFFIX[all_platforms[x].name] = all_platforms[x].lib_suffix

end

# Load nodes in IseCluster

$VALID_DRONES   = []
$DRONE_PLATFORM = Hash.new

Node.includes(:platform).each do |drone|

  $VALID_DRONES << drone.name
  $DRONE_PLATFORM[drone.name] = drone.platform.name

end




