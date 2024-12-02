##########################################################
###
##  File: ruby_stk_track_insert.rb
##  Desc: Inserts Tracks into STK from ISE TruthTargetStates Messages
#

$debug_stk = $debug
$debug_sim = $debug
$debug_cmd = $debug

puts "Entering: #{File.basename(__FILE__)}" if $debug

puts "Hello, I am: unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "

require 'STK'
require 'SimTime'
require 'pathname'

# require 'EcefCoordinate'


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
## TODO: Get the message from the command line

require 'TruthTargetStates'
require 'LLA_Vehicle_State'
require 'InitEvent'
require 'InitCase'
require 'InitCaseComplete'
require 'EndCase'
require 'EndCaseComplete'
require 'EndRun'
require 'EndRunComplete'
require 'StartFrame'

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
    StkTrackInsert.init
  end

  #############
  def self.info
    StkTrackInsert.info
  end

  #############
  def self.fini
    StkTrackInsert.fini
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

module StkTrackInsert

  ###########################################################
  ## module class variables

  @@scenario_name = "ISE"

  @@stk_ip              = nil         ## Default STK IP Address
  @@stk_port            = 5001        ## Default STK Port

  @@stk_tracks          = Hash.new    ## [track_label] = [ [lat, lon, alt], ...]
  @@label_to_id_xref    = Hash.new    ## [track_label] = stk_track_id
  @@last_stk_track_id   = 0           ## STK track ID's start at 1


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


    model_drive = Pathname.new "C:"
    model_base  = model_drive + "apps" + "AGI" + "STK 8" + "STKData" + "VO" + "Models"

    puts "DEBUG: stk model_base: #{model_base}" if $debug_sim


    granat_model_path           = model_base + "Missiles"  + "3k-10-granat.mdl"

    if $debug_sim
      puts "DEBUG: granat_model_path:           #{granat_model_path}"
    end


    unless ( STK::connect_to_stk( @@stk_port, @@stk_ip, $STKSocket, 30 ) )
      die "Unable to connect:", Get_Socket_Result(), " \n"
    end


    @@sim_time = SimTime.new( 0.1,                          ## decimal_seconds_increment
                          '27 Jul 1953 11:00:00.000',   # beginning of the Korean War
                          '27 Jul 1953 11:30:00.000' )


    if $debug_sim
      puts "DEBUG: @@sim_time.step_seconds: #{@@sim_time.step_seconds}"
      puts "DEBUG: @@sim_time.start_time:   #{@@sim_time.start_time}"
      puts "DEBUG: @@sim_time.end_time:     #{@@sim_time.end_time}"
    end




    ########################################################
    ## Initialize a new STK scenario

    puts "DEBUG: Initialize a new STK scenario" if $debug_sim


    @@results_array = STK::send_msg( $STKSocket, "CheckScenario /" )
    
    unless @@results_array[1][0] == "1"
      @@results_array = STK::send_msg( $STKSocket, "New / Scenario #{@@scenario_name}" )
    end
    
    
    
    @@results_array = STK::send_msg( $STKSocket, "Epoch * #{@@sim_time.stkfmt}" )
    @@results_array = STK::send_msg( $STKSocket, "SetAnimation * StartTime #{@@sim_time.start_time.stkfmt} EndTime #{@@sim_time.end_time.stkfmt} TimeStep #{@@sim_time.step_seconds}" )


    @@results_array = STK::send_msg( $STKSocket, "ConControl / AsyncOff VerboseOff AckOn HighSpeedOff")

    STK::ack_on($STKSocket)
    
    @@results_array = STK::send_msg( $STKSocket, "ShowUnits * Connect")

    puts "\n STK Scenario: #{@@scenario_name}"
    puts "Results of ShowUnits:"
    


    @@results_array[1].each do |a_line|
      puts a_line
    end

    puts "-"*45



    ########################################################
    ## Setup Track visuals

    @@results_array = STK::send_msg($STKSocket, "new / */MTO incoming")
    $incoming_mto_path = "*/MTO/incoming"

    # enable interpolation for all incoming tracks
    @@results_array = STK::send_msg($STKSocket, "DefaultTrack #{$incoming_mto_path} Interpolate on")


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

    options_2d.each_pair do |o, v|
        @@results_array = STK::send_msg($STKSocket, "DefaultTrack2d #{$incoming_mto_path} #{o} #{v}")
        @@results_array = STK::send_msg($STKSocket, "DefaultTrack3d #{$incoming_mto_path} #{o} #{v}")
    end

    ############################
    # set the 3d default options

    options_3d.each_pair do |o, v|
        @@results_array = STK::send_msg($STKSocket, "DefaultTrack3d #{$incoming_mto_path} #{o} #{v}")
    end








    puts "DEBUG: Completed setup of visuals" if $debug_sim







    ##########################################################
    ## Subscribe to IseRubyModel-specific messages

    TruthTargetStates.subscribe(StkTrackInsert.method(:log_message))
    LLA_Vehicle_State.subscribe(StkTrackInsert.method(:log_message))

    ############################################################################
    ## Typical control messages used with the FrameController and TimeController

    InitEvent.subscribe(StkTrackInsert.method(:log_message))

#    StartFrame.subscribe(StkTrackInsert.method(:start_frame))
#    EndFrameRequest.subscribe(StkTrackInsert.method(:end_frame))
#    EndFrameCommand.subscribe(StkTrackInsert.method(:end_frame))

    StatusRequest.subscribe(StkTrackInsert.method(:status_request))

    InitCase.subscribe(Peerrb::MonteCarlo.method(:init_case))
    EndCase.subscribe(Peerrb::MonteCarlo.method(:end_case))
    EndRun.subscribe(Peerrb::MonteCarlo.method(:end_run))

#    AdvanceTimeRequest.subscribe(Peerrb::MonteCarlo.method(:step))





    Peerrb.rate=0.0     # rate pf zerp signals no need for time stepping


  end ## end of self.init


  #######################
  def self.status_request(a_header=nil, a_message=nil)
    puts "status_request"
    OkStatusResponse.publish
  end


  ####################
  def self.start_frame(a_header=nil, a_message=nil)
    puts "start_frame"

    EndFrameOkResponse.publish
  end


  ####################
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
      case a_message.class.to_s
      when 'TruthTargetStates' then
        puts "   time_:     #{a_message.time_}"
        puts "   position_: #{a_message.position_}"
        puts "   attitude_: #{a_message.attitude_}"

      when 'LLA_Vehicle_State' then
        puts "   time_:     #{a_message.time_}"
        puts "   lla_:      #{a_message.lla_}"
        puts "   velocity_: #{a_message.velocity_}"
        puts "   attitude_: #{a_message.attitude_}"
        puts "   unitID_:   #{a_message.unitID_}"

        insert_track_into_stk(a_header, a_message)

      else
        puts "   " + a_message.raw.to_hex
      end
    end

    $stdout.flush

  end ## end of def self.log_message(a_header, a_message=nil)

  ############################################################
  ## Insert a new position for a track into STK

  def self.insert_track_into_stk(sam_hdr, msg)

    ise_track_id = "#{sam_hdr.peer_id_}-#{sam_hdr.unit_id_}"
    
    if msg.unitID_ < 100   ## Only insert tracks from RamThreat (100> come from StkMissileDriver)
      @@stk_tracks[ise_track_id] = [] unless @@stk_tracks.include? ise_track_id
      @@stk_tracks[ise_track_id] << msg.lla_

      send_new_track_position(ise_track_id, msg.time_, msg.lla_)
    end

  end ## end of def insert_track_into_stk

  ###################################################
  ## Send the appropriate Connect command to STK for
  ## this new position.

  def self.send_new_track_position(track_label, a_time_offset, a_position)

    # make sim_time consistent with received position message
    
    @@sim_time.sim_time = @@sim_time.start_time + a_time_offset

    # check label see if STK has a track_id for it yet

    unless @@label_to_id_xref.include? track_label
        
      @@last_stk_track_id += 1
      @@label_to_id_xref[track_label] = @@last_stk_track_id

      puts "INFO: New track labeled: #{track_label}    Assigned track ID: #{@@last_stk_track_id}" if $verbose


      ####################
      # create a new track
      @@results_array = STK::send_msg($STKSocket, "Track #{$incoming_mto_path} Remove #{@@last_stk_track_id} 0")
      @@results_array = STK::remark($STKSocket, "Track #{$incoming_mto_path} Remove #{@@last_stk_track_id} 0") if $verbose

      @@results_array = STK::send_msg($STKSocket, 
                                      "Track #{$incoming_mto_path} Add #{@@last_stk_track_id}" +
                                      " 1 TLLA #{@@sim_time.stkfmt}" + 
                                      " #{a_position.join(' ')}")
      @@results_array = STK::remark($STKSocket, 
                                    "Track #{$incoming_mto_path} Add #{@@last_stk_track_id}" +
                                    " 1 TLLA #{@@sim_time.stkfmt}" +
                                    " #{a_position.join(' ')}") if $verbose

      @@results_array = STK::send_msg($STKSocket, "Track #{$incoming_mto_path} Name #{@@last_stk_track_id} \"#{track_label}\"")
      @@results_array = STK::remark($STKSocket, "Track #{$incoming_mto_path} Name #{@@last_stk_track_id} \"#{track_label}\"") if $verbose
      
    else

      ########################################
      # send new position for the stk track_id

#     ecef_position = EcefCoordinate.new a_position
#     lla_position  = ecef_position.to_lla

      @@results_array = STK::send_msg($STKSocket, 
                                      "Track #{$incoming_mto_path} Extend #{@@label_to_id_xref[track_label]}" + 
                                      " 1 TLLA #{@@sim_time.stkfmt}" + 
                                      " #{a_position.join(' ')}")
    
    end

  end ## end of def self.send_new_track_position

end ## module StkTrackInsert

puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose


