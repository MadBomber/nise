#########################################################################
###
##  File:   web_app_feeder.rb (InterceptorFarmModel)
##  Desc:   This is an IseModel that acts as a proxy for web-based applications
##          with regard to the subscription to IseMessages.  Two command line
##          parameters are required.  The first is the name of the system
##          environment variable that defines the URI to which IseMessage content is
##          to be pushed using an HTTP 1.1 post event  The second required command
##          line parameter is a comma seperated list of IseMessage names which
##          this IseModel is to subscribe.

# TODO: delete this!!! shouldn't be in AADSE shouldn't be in ISE
#require 'aadse_utilities'
#require 'aadse_database'


require 'SimTime'
require 'debug_me'
require 'rest_client'     # full RESTful interaction with a web site

$sim_time = SimTime.new

begin
  if Peerrb::VERSION
    # FIXME: Logging is broken because it relied on AADSE
    #log_this "=== Loaded by the RubyPeer ==="
    $running_in_the_peer = true
  end
rescue
  $running_in_the_peer = false
  # FIXME: Logging is broken because it relied on AADSE
  #log_this "=== Running in test mode outside of the RubyPeer ==="
  require 'dummy_connection'

  $verbose, $debug  = false, false
  
  $OPTIONS = Hash.new
  $OPTIONS[:unit_number] = 1
  
  require 'ostruct'
  $model_record = OpenStruct.new
  $model_record.name  = 'WebAppFeeder'
  
  $run_model_record = OpenStruct.new
  $run_model_record.rate = 0.0
  
  require 'peerrb_module'
end


module WebAppFeeder

  $last_unit_id = (100 * $OPTIONS[:unit_number]) - 1

  libs = Peerrb.register(
    self.name, 
    :monte_carlo  => true,
    :framed_controller => true,
    :timed_controller => true,
    :messages     =>  [ # model specific messages are loaded in process_command_line
                      ]
  )



  mattr_accessor :my_pathname
  mattr_accessor :my_directory
  mattr_accessor :my_filename
  mattr_accessor :my_lib_directory

  @@my_pathname       = Pathname.new __FILE__
  @@my_directory      = @@my_pathname.dirname
  @@my_filename       = @@my_pathname.basename.to_s
  @@my_lib_directory  = @@my_directory + @@my_filename.split('.')[0].to_camelcase

  # FIXME: Logging is broken because it relied on AADSE
  #log_this "Entering: #{my_filename}" if $debug or $verbose
  #log_this "Hello, I am: unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "


  ######################################################
  ## Load libraries specific to this IseRubyModel

  @@my_lib_directory.children.each do |lib_name|
    if lib_name.fnmatch? '*.rb'
      # FIXME: Logging is broken because it relied on AADSE
      #log_this "#{my_filename} is loading #{lib_name} ..." if $debug or $verbose
      require lib_name
    end
  end
  

  process_command_line


  ######################################################
  ## Define the web applications receiving controller for IseMessage
  ## post events.

  url       = $OPTIONS[:url]
  # FIXME: This is broken because it relied on AADSE
  #username  = 'aadse'
  #password  = username

  $web_app = RestClient::Resource.new(url) #, username, password)

end ## module WebAppFeeder

# end of web_app_feeder.rb
#########################################################################
