##########################################################
###
##  File: ScenarioDriverModel.rb
##  Desc: An example of a ruby model using the ISE protocol to drive a scenario
#

#$debug = true

puts "Entering: #{File.basename(__FILE__)}" if $debug


puts "Hello, I am: unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "

pp $OPTIONS if $debug

######################################################
## Example of how to load libraries specific
## to this IseRubyModel

path_to_me = File.expand_path(File.dirname(__FILE__))




############################################
## process command line parameters

$OPTIONS[:scenario] = nil
$OPTIONS[:rate]     = 0.1

ARGV.options do |o|

  o.on("-r", "--rate=decimal_seconds", Float, "Step rate in decimal seconds. Default: #{$OPTIONS[:rate]}")      { |o| $OPTIONS[:rate] = o }
  o.on("-s", "--scenario=file_name", String, "Scenario file to drive.")      { |o| $OPTIONS[:scenario] = o }
  o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
  o.parse!

end ## end of ARGV.options do

unless $OPTIONS[:scenario]
  $stderr.puts
  $stderr.puts "WARNING: #(__FILE__) has no scenario to drive."
  $stderr.puts "         ... so will just hang around doing nothing."
  $stderr.puts  
end

puts "DEBUG: after processing command line" if $debug
pp $OPTIONS if $debug

################################################
## require the message libraries to be used in
## this IseRubyModel

require 'SimTime'
require 'IseScenario'


puts "DEBUG:   Before loading #{$OPTIONS[:scenario]}" if $debug
require $OPTIONS[:scenario] if $OPTIONS[:scenario]
puts "DEBUG:   After loading #{$OPTIONS[:scenario]}" if $debug

require 'InitEvent'

require 'InitCase'
require 'InitCaseComplete'

require 'EndCase'
require 'EndCaseComplete'

require 'EndRun'
require 'EndRunComplete'

require 'StartFrame'
require 'EndFrame'


require 'ControlMessages'
require 'AdvanceTime'
#require 'TimeAdvanced'



###################################################
## Print out the command line options

if $debug or $verbose
  pp ARGV
  puts '='*60
end


########################################
## Over-ride the Peerrb required methods

module Peerrb

  #############
  def self.init
    ScenarioDriverModel.init
  end
  
  #############
  def self.info
    ScenarioDriverModel.info
  end
  
  #############
  def self.fini
    ScenarioDriverModel.fini
  end


# Here are some additional Peerrb methods that can be over-riden by an IseRubyModel

  module MonteCarlo
  
    #############
  	def self.init_case(header=nil, message=nil)
  	  puts "MonteCarlo#init_case" if $debug
  	  # ... do stuff ...
  	  init_case_complete = InitCaseComplete.new
#  	  init_case_complete.case_number_ = message.case_number_
  	  init_case_complete.publish
  	end
  	
  	########
		def self.step(header=nil, message=nil)
  	  puts "MonteCarlo#step" if $debug
      # ... do stuff ...
      TimeAdvanced.published
    end
		
		############
		def self.end_case(header=nil, message=nil)
  	  puts "MonteCarlo#end_case" if $debug
  	  # ... do stuff ...
  	  end_case_complete = EndCaseComplete.new
#  	  end_case_complete.case_number_ = message.case_number_
  	  end_case_complete.publish
 		end
		
		###########
		def self.end_run(header=nil, message=nil)
  	  puts "MonteCarlo#end_run" if $debug
  	  # ... do stuff ...
  	  end_run_complete = EndRunComplete.new
#  	  end_run_complete.case_number_ = message.case_number_
  	  end_run_complete.publish
  	  
  	  Peerrb::fini
  	  
		end

  end ## end of module MonteCarlo



  
end ## moduel Peerrb over-rides


############################################################
## A silly IseRubyModel

module ScenarioDriverModel

  ###########################################################
  # These are the over-rides of the Peerrb required methods #
  ###########################################################
  
  ##########################################################
  ## init is invoked after a successful connections has been
  ## established with the IseDispatcher
  
  def self.init

    puts "The IseRubyModel has over-riden the Peerrb.init method" if $debug or $verbose
    
    $sim_time = SimTime.new unless defined? $sim_time

############################################################################
## Typical control messages used with the FrameController and TimeController

#    InitEvent.subscribe(ScenarioDriverModel.method(:log_message))

    StartFrame.subscribe(ScenarioDriverModel.method(:start_frame)) if $OPTIONS[:rate] > 0.0
#    EndFrame.subscribe(ScenarioDriverModel.method(:end_frame))
#    EndFrameRequest.subscribe(ScenarioDriverModel.method(:end_frame))
#    EndFrameCommand.subscribe(ScenarioDriverModel.method(:end_frame))
    
#    StatusRequest.subscribe(ScenarioDriverModel.method(:status_request))

    InitCase.subscribe(Peerrb::MonteCarlo.method(:init_case))
    EndCase.subscribe(Peerrb::MonteCarlo.method(:end_case))
    EndRun.subscribe(Peerrb::MonteCarlo.method(:end_run))
    
#    AdvanceTime.subscribe(ScenarioDriverModel.method(:advance_time))


    IseScenario.instances.each do |s|
      s.run(0.0)
    end



    Peerrb.rate               = $OPTIONS[:rate]
    $sim_time.step_seconds    = $OPTIONS[:rate]
    IseScenario.runtime_step  = $OPTIONS[:rate]
    
    
    if $debug
      if $OPTIONS[:unit_number] == 2
        if $OPTIONS[:rate] > 0.0
          $stderr.puts ""
          $stderr.puts "ERROR ERROR ERROR"
          $stderr.puts ""
          $stderr.puts " $OPTIONS[:rate] -= > #{$OPTIONS[:rate]}"
          $stderr.puts ""
        end
      end
    end
    
    Peerrb.rate = 0.0
    Peerrb.model_ready
    
  end ## end of self.init
  
  
  
  
  
  #######################
  def self.advance_time(a_header=nil, a_message=nil)
    puts "advance_time"
    TimeAdvanced.publish
  end

  
  #######################
  def self.status_request(a_header=nil, a_message=nil)
    puts "status_request" if $debug
    OkStatusResponse.publish
  end
  
  
  ####################
  def self.start_frame(a_header=nil, a_message=nil)
#    $stderr.puts "start_frame w/ $sim_time.offset: #{$sim_time.offset}" # if $debug
    $sim_time.advance_time
    IseScenario.instances.each do |s|
      s.run($sim_time.offset)
    end

    end_frame = EndFrame.new
    end_frame.publish
    
  end

  
  ####################
  def self.end_frame(a_header=nil, a_message=nil)
    puts "end_frame" if $debug
    EndFrameOkResponse.publish
  end

  
  #############################################################################
  ## fini is invoked after the connection to the IseDispatcher has been dropped
  
  def self.fini
    puts "The IseRubyModel has over-riden the Peerrb.fini method" if $debug or $verbose

=begin
    if $debug    
      puts "-"*15
      puts "$connection.msg_queue contains these messages:"
      $connection.msg_queue.each do |mq|
        puts "#{mq[0]} -=> #{mq[1].to_hex}"
      end

      puts "-"*15
      puts "$connection.out_msg contains these messages:"
      $connection.out_msg.each do |mq|
        puts "#{mq[0]} -=> #{mq[1].to_hex}"
      end
    end
=end

    Peerrb::really_fini

  end ## end of def self.fini
  
  ################################################################################
  ## info is invoked to provide status information about the state of the IseModel
  
  def self.info
    puts "The IseRubyModel has over-riden the Peerrb.info method"   if $debug or $verbose
  end ## end of def self.info
  
  
  ####################################################
  ## IseRubyModel specific methods to implement the ##
  ## unique functionality of this IseRubyModel      ##
  ####################################################
  
  
  
  ###############################################
  ## A generic callback to dump incoming messages
  
  def self.log_message(a_header, a_message=nil)
  
    if $debug
      puts "Start: "+"="*60
      puts "dump_message callback in the IseRubyModel just received this message:"
      puts "#### HEADER ####"
      puts a_header.to_s
      pp a_header
      if a_message
        puts "#### MESSAGE ####"
        puts a_message.to_s
        pp a_message
      end
      puts "End:" + "-"*60
    else
      puts "Unit: #{a_header.unit_id_} sent #{a_message.class}"
      
      if a_message.msg_items.length > 0
      
        max_length = 0
        
        a_message.msg_items.each do |mi|
          mi_l=mi[0].to_s.length
          max_length = mi_l if mi_l > max_length
        end
        
        a_message.msg_items.each do |mi|
          mi_sym   = mi[0]
          mi_s     = mi_sym.to_s
          padding  = max_length - mi_s.length + 1
          mi_value = a_message.instance_variable_get("@#{mi_sym}")
          puts "   #{mi_s}:" + " "*(padding) + "#{mi_value}"
        end
        
      end ## end of if a_message.msg_items.length > 0
      
    end ## end of if $debug
    
    $stdout.flush   ## default ruby buffer size is 32k; default only flushes when buffer full
    
  end ## end of def self.log_message(a_header, a_message=nil)

end ## module ScenarioDriverModel

puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose


