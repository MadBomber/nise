#########################################################
###
##  File:  rabbit_feeder.rb
##  Desc:  Feed the RabbitMQ AMQP Server with IseMessages
#

require 'require_all'

require 'pathname_mods'
require 'string_mods'

# <=- Add rabbit_feeder global library requirements here
#     The library files that are specific to rabbit_feeder
#     are automatically loaded in a block of code that comes later.




########################################################
## The following begin/rescue/end block is only necessary
## if you intend to test this model outside of a normally
## running IseJob ... which by the way, unit testing is always
## a good idea.

begin
  if Peerrb::VERSION
    puts "=== Loaded by the RubyPeer ==="
    $running_in_the_peer = true
  end
rescue
  require 'ise_logger'
  ISE::Log.new
    
  $running_in_the_peer = false
  puts "=== Running in test mode outside of the RubyPeer ==="
  require 'dummy_connection'

  $verbose, $debug  = false, false

  $OPTIONS = Hash.new
  $OPTIONS[:unit_number] = 1

  require 'ostruct'
  $model_record = OpenStruct.new
  $model_record.name  = 'RabbitFeeder'
  
  ISE::Log.progname = $model_record.name

  $run_model_record = OpenStruct.new
  $run_model_record.rate = 0.0

  require 'peerrb_module'
end

########################################################
## The follow module defines the model's basic existence.
## The code in this module block is executed at the time
## that it is loaded (e.g. required) by the RubyPeer.

module RabbitFeeder

  ###############################################################
  ## Register rabbit_feeder with the IseDatabase
  ## Load all required IseMessage libraries
  
  libs = Peerrb.register(
    self.name,
    :monte_carlo => true    # This line is required for InitCase and EndCase messages
  )


  ###########################################################################
  ## This secontion of code deals with the model finding itself within
  ## the file system so that it can load any of its

  mattr_accessor :my_pathname
  mattr_accessor :my_directory
  mattr_accessor :my_filename
  mattr_accessor :my_lib_directory
  mattr_accessor :my_input_filepath
  
  @@my_pathname         = Pathname.new __FILE__
  @@my_directory        = @@my_pathname.dirname
  @@my_filename         = @@my_pathname.basename.to_s
  @@my_filename_sans_rb = @@my_filename.split('.')[0]
  @@my_lib_directory    = @@my_filename_sans_rb.to_camelcase

  # Setup Connection to an Input file (if not defined, will be nil)
  job_id      = $run_record.job_id
  model_id    = $model_record.id
  unit_number = $OPTIONS[:unit_number]
  
  @@my_input_filepath = JobConfig.get_input_file(job_id, model_id, unit_number)

  ISE::Log.debug "Entering: #{my_filename}"
  ISE::Log.debug "unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "
  ISE::Log.debug("input from: #{@@my_input_filepath}") unless @@my_input_filepath
 

  ######################################################
  ## Load libraries specific to this IseRubyModel

  require_rel "#{@@my_lib_directory}/*.rb"    # go only 1 level deep

  #######################################################
  ## At this point all require libraries both global and
  ## specific to rabbit_feeder have been loaded.

  process_command_line  # <=- delete this line if there are no command line parameters used


  ####################################################
  ## IseRubyModel specific methods to implement the ##
  ## unique functionality of this IseRubyModel      ##
  ####################################################


  # <=- place any other method definitions, or initialization
  #     code that is necessary at load time.

end ## end of module RabbitFeeder
