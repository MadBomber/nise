#####################################################################
###
##  File: stk_missile_driver.rb
##  Desc: Sends 'connect' commands to STK to create and fly a Missile
##        object on a balistic course.
##
##  TODO: Retrofit the improvements made using the STK and StkMessage libraries
#

$debug     = false
$debug_stk = $debug
$debug_sim = $debug
$debug_cmd = $debug

$publish_stk_missile_positions = true

puts "Entering: #{File.basename(__FILE__)}" if $debug

puts "Hello, I am: unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "

require 'STK'
#require 'StkMessage'   ## TODO: Add the StkMessage library and update the rest of the file using the new DSL
require 'SimTime'
require 'pathname'


$sim_time = SimTime.new(  0.1,
                          '27 Jul 1953 11:00:00.000',   # beginning of the Korean War
                          '27 Jul 1953 11:30:00.000' )



#################################################
## alias the long method name with a shorter name
## After the alias  STK::send_msg
## and              STK::process_connect_command
## are the same.

module STK
  class << self
    alias :send_msg :process_connect_command
  end
end

################################################
## require the message libraries to be used in
## this IseRubyModel

require 'StkLaunchMissile'
require 'LLA_Vehicle_State'

require 'StartFrame'
require 'EndFrame'

require 'InitEvent'

require 'InitCase'
require 'InitCaseComplete'

require 'EndCase'
require 'EndCaseComplete'

require 'EndRun'
require 'EndRunComplete'

require 'ControlMessages'
require 'AdvanceTime'
#require 'TimeAdvanced'

require 'RegisterEndEngage'
require 'EndEngagement'


###################################################
## Print out the command line options

if $debug or $verbose
  puts "$OPTIONS -=>"
  pp $OPTIONS
  puts "ARGV -=>"
  pp ARGV
  puts '='*60
  $stdout.flush
end




########################################
## Over-ride the Peerrb required methods

module Peerrb

  #############
  def self.init
    StkMissileDriver.init
  end

  #############
  def self.info
    StkMissileDriver.info
  end

  #############
  def self.fini
    StkMissileDriver.fini
  end


  # Here are some additional Peerrb methods that can be over-riden by an IseRubyModel

  module MonteCarlo

    #############
    def self.init_case(header=nil, message=nil)
      puts "MonteCarlo#init_case"
      # ... do stuff ...
      init_case_complete = InitCaseComplete.new
      #       init_case_complete.case_number_ = message.case_number_
      init_case_complete.publish
    end

    ########
    def self.step(header=nil, message=nil)
      puts "MonteCarlo#step"
      # ... do stuff ...
      TimeAdvanced.published
    end

    ############
    def self.end_case(header=nil, message=nil)
      puts "MonteCarlo#end_case"
      # ... do stuff ...
      end_case_complete = EndCaseComplete.new
#      end_case_complete.case_number_ = message.case_number_
      end_case_complete.publish
    end

    ###########
    def self.end_run(header=nil, message=nil)
      puts "MonteCarlo#end_run"
      # ... do stuff ...
      end_run_complete = EndRunComplete.new
      #       end_run_complete.case_number_ = message.case_number_
      end_run_complete.publish
      
      Peerrb::fini
      
    end

  end ## end of module MonteCarlo




end ## moduel Peerrb over-rides


############################################################
## A silly IseRubyModel

module StkMissileDriver

  ###########################################################
  ## module class variables

  @@scenario_name = "ISE"
  
  @@returned_results    = []          ## results returned by STK

  @@stk_ip              = nil         ## Default STK IP Address
  @@stk_port            = 5001        ## Default STK Port
  
  @@missiles            = []          ## array of labels from the StkLaunchMissile message
  @@missile_class       = '*/Missile' ## STK Missile Object Path Prefix

  @@missile_model_pathbase  = Pathname.new("C:") + "apps" + "AGI" + "STK 8" + "STKData" +
                              "VO" + "Models" + "Missiles"

  @@icbm_model_path     = @@missile_model_pathbase + "taepodong-2.mdl"
  @@scud_model_path     = @@missile_model_pathbase + "scud-missile.mdl"
  @@thaad_model_path    = @@missile_model_pathbase + "thaad.mdl"
  @@patriot_model_path  = @@missile_model_pathbase + "patriot_missile.mdl"


  @@lla_vehicle_state   = LLA_Vehicle_State.new


  ###########################################################
  # These are the over-rides of the Peerrb required methods #
  ###########################################################

  ##########################################################
  ## init is invoked after a successful connections has been
  ## established with the IseDispatcher

  def self.init

    puts "The IseRubyModel has over-riden the Peerrb.init method" if $debug or $verbose

    #########################################################
    ## Process the command line arguments
    ## expecting only 1 item in the following form:
    ##    --stk 138.209.69.248[:5001]

    @@stk_ip    = "138.209.69.248"  ## default: Dewayne's Windoze machine
    @@stk_port  = 5001

    $OPTIONS[:stk] = nil

    ## over-rid defaults with command line parameters

    ARGV.options do |o|

      o.on("-s", "--stk=ip[:port]", String, "IP address and port of STK visualizer")      { |$OPTIONS[:stk]| }
      o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
      o.parse!

    end ## end of ARGV.options do

    puts "DEBUG: $OPTIONS[:stk] -=> #{$OPTIONS[:stk]}" if $debug or $verbose

    if $OPTIONS[:stk]

      stk = $OPTIONS[:stk].split(':')
      stk << @@stk_port unless stk.length > 1

      @@stk_ip    = stk[0]
      @@stk_port  = stk[1]

    end

    ## over-ride command-line with environment variable

    @@stk_ip    = ENV['STK_IP']   if ENV['STK_IP']
    @@stk_port  = ENV['STK_PORT'] if ENV['STK_PORT']    ## over-ride default with environment variable


    puts "DEBUG: stk ip/port used: #{@@stk_ip} / #{@@stk_port}" if $debug or $verbose

    #########################################################
    ## Initialize the connection to STK

    $STKSocket = 'Socket1'    ## any 'ol name will do

    puts "DEBUG: stk ip/port: #{@@stk_ip}/#{@@stk_port}" if $debug_sim



    unless ( STK::connect_to_stk( @@stk_port, @@stk_ip, $STKSocket, 30 ) )
      die "Unable to connect:", Get_Socket_Result(), " \n"
    end




    if $debug_sim
      puts "DEBUG: $sim_time.step_seconds: #{$sim_time.step_seconds}"
      puts "DEBUG: $sim_time.start_time:   #{$sim_time.start_time}"
      puts "DEBUG: $sim_time.end_time:     #{$sim_time.end_time}"
    end




    ########################################################
    ## Initialize a new STK scenario

    puts "DEBUG: Initialize a new STK scenario" if $debug_sim


    @@results_array = STK::send_msg( $STKSocket, "CheckScenario /" )
    
    unless @@results_array[1][0] == "1"
      @@results_array = STK::send_msg( $STKSocket, "New / Scenario #{@@scenario_name}" )
    end
    
    
    
    @@results_array = STK::send_msg( $STKSocket, "Epoch * #{$sim_time.stkfmt}" )
    @@results_array = STK::send_msg( $STKSocket, "SetAnimation * StartTime #{$sim_time.start_time.stkfmt} EndTime #{$sim_time.end_time.stkfmt} TimeStep #{$sim_time.step_seconds}" )


   @@results_array = STK::send_msg( $STKSocket, "ConControl / AsyncOff VerboseOff AckOn HighSpeedOff")




    @@results_array = STK::send_msg( $STKSocket, "ShowUnits * Connect")

    puts "\n STK Scenario: #{@@scenario_name}"
    puts "Results of ShowUnits:"

    @@results_array[1].each do |a_line|
      puts a_line
    end

    puts "-"*45



    ########################################################
    ## Setup visuals

    options_2d = Hash.new
    options_2d = {
                    'Show'              => 'On',
                    'ShowLine'          => 'On',
                    'ShowLabel'         => 'On',
                    'ShowMarker'        => 'On',
                    'Color'             => 'red',
                    'MarkerColor'       => 'red',
                    'LineColor'         => 'red',
                    'LabelColor'        => 'red',
                    'LineWidth'         => '2',
                    'LineStyle'         => 'Solid',
                    'MarkerStyle'       => 'Square',
                    'UsePreFadetime'    => 'Off',
                    'UsePostFadetime'   => 'Off',
                    'UseDisplayTime'    => 'Off'    }


    options_3d = Hash.new
    options_3d = {
                    'Show'                  => 'On',
                    'UseLabelOffset'        => 'On',
                    'LabelOffsetInPixels'   => 'On',
                    'LabelOffset'           => '8 8 8',
                    'Marker Show'           => 'On',
                    'Marker MarkerType'     => 'Line Shape Star'   }

    ############################
    # set the 2d default options

#    options_2d.each_pair do |o, v|
#        @@results_array = STK::send_msg($STKSocket, "DefaultTrack2d #{$incoming_mto_path} #{o} #{v}")
#        @@results_array = STK::send_msg($STKSocket, "DefaultTrack3d #{$incoming_mto_path} #{o} #{v}")
#    end

    ############################
    # set the 3d default options

#    options_3d.each_pair do |o, v|
#        @@results_array = STK::send_msg($STKSocket, "DefaultTrack3d #{$incoming_mto_path} #{o} #{v}")
#    end








    puts "DEBUG: Completed setup of visuals" if $debug_sim







    ##########################################################
    ## Subscribe to IseRubyModel-specific messages

    StkLaunchMissile.subscribe(StkMissileDriver.method(:launch_missile))



    ############################################################################
    ## Typical control messages used with the FrameController and TimeController

#    InitEvent.subscribe(StkMissileDriver.method(:log_message))

    StartFrame.subscribe(StkMissileDriver.method(:start_frame))
#    EndFrameRequest.subscribe(StkMissileDriver.method(:end_frame))
#    EndFrameCommand.subscribe(StkMissileDriver.method(:end_frame))
    
#    AdvanceTime.subscribe(StkMissileDriver.method(:advance_time))

    StatusRequest.subscribe(StkMissileDriver.method(:status_request))

    InitCase.subscribe(Peerrb::MonteCarlo.method(:init_case))
    EndCase.subscribe(Peerrb::MonteCarlo.method(:end_case))
    EndRun.subscribe(Peerrb::MonteCarlo.method(:end_run))

#    AdvanceTimeRequest.subscribe(Peerrb::MonteCarlo.method(:step))


    # SMELL: Big smell; FramedController functionality is comprimized
    #        The FramedController sends out and EndCase after all models
    #        who have published RegisterEndEngage have signaled that they
    #        are at EndEngagement.
    ree = RegisterEndEngage.new
    ree.publish
    
    

    Peerrb.rate=0.1     # 10Hz means -=> 10 times a second


  end ## end of self.init


  #######################
  def self.advance_time(a_header=nil, a_message=nil)
    puts "advance_time"
    TimeAdvanced.publish
  end


  #######################
  def self.status_request(a_header=nil, a_message=nil)
    puts "status_request"
    OkStatusResponse.publish
  end


  ####################
  def self.start_frame(a_header=nil, a_message=nil)
    puts "start_frame" if $debug
    
    $sim_time.advance_time
  
    if $publish_stk_missile_positions
      if @@missiles.length > 0
        m_cnt = 0
        @@missiles.each do |m|
          m_cnt += 1
          
          @@returned_results = STK::send_msg( $STKSocket, "Position #{m} #{$sim_time.stkfmt}")    

          puts "STK Missile Object #{m} Position -=> #{@@returned_results[1][0..2].join(',')}" if $debug
          
          if 'ACK' == @@returned_results[0]
            mprda = @@returned_results[1][0].chomp.split(' ') ## missile position return data array
            @@lla_vehicle_state.unitID_   = m_cnt + 100       ## adding 100 to discriminate msg from those sent by RamThreat
            @@lla_vehicle_state.time_     = $sim_time.offset  # decimal seconds from start time of sim
            @@lla_vehicle_state.lla_      = [ mprda[0].to_f, mprda[1].to_f, mprda[2].to_f ]
            @@lla_vehicle_state.velocity_ = [ mprda[3].to_f, mprda[4].to_f, mprda[5].to_f ] # FIXME: check docs on results from STK
            @@lla_vehicle_state.attitude_ = [ 0.0, 0.0, 0.0 ] # FIXME: STK version 8 does not provide attitude
            @@lla_vehicle_state.publish
          end
          
        end ## end of @@missiles.each do |m|
      end ## end of if @@missiles.length > 0
    end ## end of if $publish_stk_missile_positions
    
#    EndFrameOkResponse.publish

    end_frame = EndFrame.new
    end_frame.publish

  end ## end of def self.start_frame


  ###############################################
  def self.end_frame(a_header=nil, a_message=nil)
    puts "end_frame"
    EndFrameOkResponse.publish
  end


  #############################################################################
  ## fini is invoked after the connection to the IseDispatcher has been dropped

  def self.fini
    puts "The IseRubyModel has over-riden the Peerrb.fini method" if $debug or $verbose

    puts "DEBUG: closing connection to STK" if $debug_sim

    STK::close_connection_to_stk( $STKSocket )

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
    
        
    Peerrb::really_fini


  end ## end of def self.fini

  ################################################################################
  ## info is invoked to provide status information about the state of the IseModel

  def self.info
    puts "The IseRubyModel has over-riden the Peerrb.info method"   if $debug or $verbose
#    stub "info report"
  end ## end of def self.info


  ####################################################
  ## IseRubyModel specific methods to implement the ##
  ## unique functionality of this IseRubyModel      ##
  ####################################################



  ###############################################
  ## Handle the StkLaunchMissile messages

  def self.launch_missile(a_header, a_message)
  
    missile_label = a_message.label_.chomp
  
    @@missiles << @@missile_class + '/' + missile_label
    missile_object = @@missiles.last
    
    if $debug
      puts "== Received StkLaunchMissile =="
      pp a_message
      pp @@missiles
    end
    
    @@returned_results = STK::send_msg( $STKSocket, "New / #{@@missile_class} #{missile_label}" )
    
    case missile_label
      when /icbm/
        model_path  = @@icbm_model_path.to_s
        model_color = "red"
      when /scud/
        model_path  = @@scud_model_path.to_s
        model_color = "red"
      when /cf/
        model_path  = @@patriot_model_path.to_s
        model_color = "blue"
      else
        model_path  = @@scud_model_path.to_s
        model_color = "red"
    end
    
    @@returned_results = STK::send_msg( $STKSocket, "VO #{missile_object} Model File #{} Use ModelFile")
    
    @@returned_results = STK::send_msg( $STKSocket, "VO #{missile_object} Pass TrajLead None")
    @@returned_results = STK::send_msg( $STKSocket, "VO #{missile_object} Pass TrajTrail All")
    @@returned_results = STK::send_msg( $STKSocket, "VO #{missile_object} Pass GrndLead None")
    @@returned_results = STK::send_msg( $STKSocket, "VO #{missile_object} Pass GrndTrail None")
    
    ["Label", "Marker", "GroundTrack"].each do |item|
      @@returned_results = STK::send_msg( $STKSocket, "Graphics #{missile_object} SetColor #{model_color} #{item}")
    end
    
    @@returned_results = STK::send_msg( $STKSocket, "Missile #{missile_object} TRAJECTORY #{$sim_time.stkfmt} #{$sim_time.step_seconds} LnLatGeoD #{a_message.launch_position_.join(' ')} DeltaV 0.0 ImLatGeoD #{a_message.target_position_.join(' ')}")

  end ## end of def self.launch_missile(a_header, a_message=nil)


end ## module StkMissileDriver

puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose


