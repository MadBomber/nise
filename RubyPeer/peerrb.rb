#!/usr/bin/env ruby
##########################################################
###
##  File: peerrb.rb
##  Desc: The ruby version of peerd
##
##  Expect the command line parameters to work the same way as with peerd.
##  For example, -l command loads the Ruby model using the $RUBYLIB environment
##  variable in the same way that peerd loads its C++ model using the $LD_LIBRARY_PATH
#

# TODO: Expand the IseRubyPeer to allow multiple IseRubyModels to be loaded.

####################################################
## System-wide globals

$,            = ', '    ## used in pretty printing arrays for debug statements
$debug_io     = false   ## if run will dump everything coming and going
$start_time   = Time.now

$msg_sent_cnt = 0       ## TODO: Move $connection stats into the IseRouter
$msg_rcvd_cnt = 0

$normal_completion = false  ## Helps the at_exit trap know that things happened abnormally

############################
## From $ISE_ROOT/Portal/lib

require 'rubygems'
require 'ise_logger'
ISE::Log.new
require 'IseDatabase'
require 'IseDispatcher'
require 'systemu'
require 'string_mods'

# TODO: Move $connected_to_dispatcher functionality into the IseRouter::Dispatcher class
$connected_to_dispatcher = false  ## Used to indicate a successful connection to the IseDispatcher

###############################
## RubyPeer Specific Libraries

require 'process_command_line'

ISE::Log.progname = "#{$OPTIONS[:model_name]}-#{$OPTIONS[:unit_number]}"

require 'SimMsgType'    ## class methods which_(#), type_(sym), desc_(sym)
SimMsgType.new


#####################################################
## Get the current node's record from the IseDatabase

status, my_fqdn, stderr = systemu('hostname') ## SMELL: not cross-platform
my_fqdn.chomp!

$node_record = Node.find_by_fqdn(my_fqdn)

unless $node_record
  $stderr.puts "ERROR: this computer is not registered in the IseDatabase."
  ISE::Log.fatal "#{my_fqdn} is not registered in the IseDatabase"
  exit(-1)
end


############################################################
## Used to cache app_message records primarily for access to
## the id by the publish_message method

# SMELL: $app_message_cache may no longer be used
$app_message_cache = Hash.new


############################################################
## Create the RunPeer record for this IseRubyModel

$run_peer_record = RunPeer.new
$run_peer_record.node_id      = $node_record.id
$run_peer_record.pid          = Process.pid
$run_peer_record.control_port = 0
$run_peer_record.status       = 0
$run_peer_record.peer_key     = $OPTIONS[:model_name]
$run_peer_record.save



if $debug
  $stderr.puts
  $stderr.puts "DEBUG: $run_peer_record.id is #{$run_peer_record.id}"
end

############################################################
## Creat the RunModel record for this IseRubyModel

$run_model_record = RunModel.new
$run_model_record.run_id            = $run_record.id
$run_model_record.run_peer_id       = $run_peer_record.id
$run_model_record.dll               = $OPTIONS[:model_name]
$run_model_record.instance          = $OPTIONS[:unit_number]
$run_model_record.dispnodeid        = $node_record.id   ## FIXME: does not account for $ISE_GATEWAY
$run_model_record.rate              = 0.0   ## default expect model to over-ride value with rate=
$run_model_record.model_ready       = false
$run_model_record.dispatcher_ready  = 0
$run_model_record.status            = 0     ## default expect model to over-ride value with status=
$run_model_record.execute_time      = 0.0
$run_model_record.extended_status   = "Ready to load IseRubyModel"  ## default, model over-rides with status=
$run_model_record.save




#######################
## Principle GEMS Used:

require 'eventmachine'


############################################
## Establish module name and global defaults

require 'peerrb_module'

######################################################
## Make sure that "this" directory is on the load path

path = File.expand_path(File.dirname(__FILE__))
$: <<  path unless $:.include?(path)



################################################################
## Clean up the IseDatabase entries for this IseRubyPeer on exit

at_exit do


  if $OPTIONS[:amqp]
  
    # TODO: change $amqp_connection to $connection[:amqp]
  
    if $amqp_connection

      #begin
      #  $amqp_connection.msg_queue.unsubscribe
      #rescue Exception => e
      #  ISE::Log.error "AMQP msg_queue#unsubscribe FAILED: #{e}"
      #end

      begin
        $amqp_connection.msg_queue.delete
      rescue Exception => e
        ISE::Log.error "AMQP msg_queue#delete FAILED: #{e}"
      end

      begin
        $amqp_connection.session.stop 
      rescue Exception => e
        ISE::Log.error "AMQP session#stop FAILED: #{e}"
      end
      
    end ## end of if $amqp_connection
  
  end ## end of if $OPTIONS[:amqp]

  $stderr.puts "#{$OPTIONS[:model_name]}-#{$OPTIONS[:unit_number]} is terminating ..."
  RunSubscriber.delete_all( "run_peer_id = #{$run_peer_record.id}" )
  RunModel.delete_all(      "run_peer_id = #{$run_peer_record.id}" )
  $run_peer_record.delete
  
  if $normal_completion
    ISE::Log.info "terminating normally"
  else
    ISE::Log.error "terminating because of errors"
  end
  
end ## end of at_exit do






###########
## Do stuff

require 'dispatcher_protocol'   if $OPTIONS[:dispatcher]
require 'load_ruby_model'


#############################################
## Support embedded web services
if $OPTIONS[:web_service]
  require 'thin'            # an event machine based rack server
  ISE::Log.info "Supporting #{$OPTIONS[:web_service]} as a web service handler with options: #{$OPTIONS[:web_service_options].inspect}"
end



########################
## Start Main Event Loop

# TODO: change $connection into a hash of available IseRouters
#       $connection becomes $connection[:dispatcher]
#       $amqp_connection becomes $connection[:amqp]
#       $control_connection becomes what??????  it is not an IseRouter

$connection         = nil ## holds the global connection to the IseDispatcher
$amqp_connection    = nil ## holds the global connection to the AMQP server
$control_connection = nil ## holds the global control connection to this RubyPeer


if $OPTIONS[:control_port]
  require 'control_protocol' 
else
  ISE::Log.info("control port for peerrb is not available.")
end

if $OPTIONS[:amqp]
  require 'amqp_protocol'
  $amqp_connection = Peerrb::AmqpProtocol.new
  ISE::Log.info("The ISE AMQP protocol is active.")
else
  ISE::Log.info("The ISE AMQP protocol is not used.")
end



# NOTE: In the new IseRouter module "vision" each IseRouter becomes a thread
#       started up within the EventMachne::run block
#       IseRouter::Dispatcher encapsulates the dispatcher_protocol
#       IseRouter::AMQP       encapsulates the amqp_protocol
#       ... etc.

$amqp_thread = nil

EventMachine::run do

=begin
# TODO: change $OPTIONS to have key :routers with value as a Hash with a key for the IseRouter
#       name and value is a Hash of options for that IseRouter
#       so that we can do something like this:

  $OPTIONS[:routers].each_pair do | ise_router, ise_router_options |
  
    IseRouter.init(ise_router, ise_router_options)
  
  end

=end

  if $OPTIONS[:dispatcher]
    EventMachine::connect($OPTIONS[:dispatcher_ip], $OPTIONS[:connection_port], Peerrb::IseProtocol) do |c|
      # init stuff
      puts "EM::connect block init"  if $debug or $verbose
      $connection = c
      ISE::Log.info("The IseDispatcher protocol is active on port #{$OPTIONS[:connection_port]}.")
    end
  end
  
  if $OPTIONS[:control_port]
  
    EventMachine::start_server($OPTIONS[:dispatcher_ip], $OPTIONS[:control_port], Peerrb::ControlProtocol) do |c|
      # init stuff
      puts "EM::start_server block init"  if $debug or $verbose or $debug_io
      $control_connection = c
      ISE::Log.info("The control protocol is active on port #{$OPTIONS[:control_port]}.")
    end
  
  end
  
  if $OPTIONS[:web_service]
    # QUESTION:  Would a threat help this process?
    $OPTIONS[:web_service].run!($OPTIONS[:web_service_options])
    ISE::Log.info("A web service is active.")
  end
  
  # Keep alive the connection to the IseDatabase
  # This supports long running (days) IseJobs like those of the MicroGrid project
  EM::add_periodic_timer(1500.0) do         # 1500 seconds is 25 minutes
    # rr = Run.find($run_model_record.run_id) # Access the IseDatabase; like a ping to stay alive
    ActiveRecord::Base.verify_active_connections!
  end

  Peerrb::init

  if $OPTIONS[:amqp]
    $amqp_thread = Thread.new do  
      $amqp_connection.route_amqp_messages
    end
    ISE::Log.info("An AMQP thread has been started.")
  end
      
  if Peerrb::model_ready?
    Peerrb::model_ready!
  else
    $stderr.puts "\nIseRubyModel is not ready; shutting it down ..."
    $stderr.puts "Did you forget 'Peerrb.model_ready' at the end of your 'init' method?"
    USE::Log.error "Model did not report ready after init"
    unbind  if $OPTIONS[:dispatcher]
  end

end ## end of EventMachine::run do


# Terminate the AMQP message routing thread
unless $amqp_thread.nil?
  $amqp_thread.kill
  ISE::Log.info("An AMQP thread has been killed.")
end


##################
## Final close out

Peerrb.fini
Peerrb.really_fini

$stop_time  = Time.new
$duration   = $stop_time - $start_time


eor_str  = "\nEnd of Run Statistics\n#{$OPTIONS[:model_name]}\nRun duration: #{$duration} seconds."
eor_str += "\nMsgs Sent: #{$msg_sent_cnt}\nMsgs Rcvd: #{$msg_rcvd_cnt}"

ISE::Log.info eor_str

unless $connected_to_dispatcher
  $stderr.puts "The IseDispatcher is _NOT_ running in the expected place: #{$OPTIONS[:dispatcher_ip]}:#{$OPTIONS[:connection_port]}"
else
  if $debug or $verbose
    $stderr.puts
    $stderr.puts "Done. #{$OPTIONS[:model_name]} (#{$OPTIONS[:unit_number]}) has terminated."
  end
end

$stdout.flush

$normal_completion = true

