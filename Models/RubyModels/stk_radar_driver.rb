#####################################################################
###
##  File: stk_radar_driver.rb
##  Desc: Sends 'connect' commands to STK to create and manipulate a radar
##        object.
#

$debug          = false
$debug_stk      = $debug
$debug_stk_ack  = $debug
$debug_sim      = $debug
$debug_cmd      = $debug
$debug_track    = $debug



puts "Entering: #{File.basename(__FILE__)}" if $debug

puts "Hello, I am: unit_number: #{$OPTIONS[:unit_number]} aka #{$model_record.name} "

require 'STK'
require 'Radar'
require 'SimTime'
require 'pathname'
require 'LlaCoordinate'


$sim_time = SimTime.new(  0.1,
            '27 Jul 1953 11:00:00.000',   # beginning of the Korean War
            '27 Jul 1953 11:30:00.000' )

$duration = $sim_time.end_time - $sim_time.start_time


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
require 'StkMissileDetected'
require 'StkTrackMissile'

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
    StkRadarDriver.init
  end

  #############
  def self.info
    StkRadarDriver.info
  end

  #############
  def self.fini
    StkRadarDriver.fini
  end


  # Here are some additional Peerrb methods that can be over-riden by an IseRubyModel

  module MonteCarlo

    #############
    def self.init_case(header=nil, message=nil)
      puts "MonteCarlo#init_case"
      # ... do stuff ...
      init_case_complete = InitCaseComplete.new
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
      end_case_complete.publish
    end

    ###########
    def self.end_run(header=nil, message=nil)
      puts "MonteCarlo#end_run"
      # ... do stuff ...
      end_run_complete = EndRunComplete.new
      end_run_complete.publish

      Peerrb::fini

    end

  end ## end of module MonteCarlo




end ## moduel Peerrb over-rides


############################################################
## A silly IseRubyModel

module StkRadarDriver

  ###########################################################
  ## module class variables

  @@scenario_name         = "ISE"       ## name of the STK scenario

  @@returned_results      = []          ## results returned by STK

  @@stk_ip                = nil         ## Default STK IP Address
  @@stk_port              = 5001        ## Default STK Port

  @@missiles              = []          ## array of STK object paths using labels from the StkLaunchMissile message
  @@missile_class         = '*/Missile' ## STK Missile Object Path Prefix

  @@tracks                = []          ## array of STK object paths using labels from the StkTrackMissile message
  @@next_track            = 0           ## The next tracks index at which to point the tracking radar

=begin
    a_missile_sop         = @@tracks[@@next_track][0] ## The STK Object Path (sop)
    target_position       = @@tracks[@@next_track][1] ## [lat, lon, alt] -=> decimal degrees; meters
    target_next_azimuth   = @@tracks[@@next_track][2] ## decimal degrees
    target_next_elevation = @@tracks[@@next_track][3] ## decimal degrees
    target_tracking       = @@tracks[@@next_track][4] ## bool; are we actively tracking this target
    tracking_radar        = @@tracks[@@next_track][5] ## the radar model instance assigned to track this target
=end




  @@stk_missile_detected  = nil

  @@radars                = []          ## array of all radars managed by this driver
  @@trackers              = []          ## array of only StaringRadars (tracking_radars)


  ###########################################################
  # These are the over-rides of the Peerrb required methods #
  ###########################################################

  ##########################################################
  ## init is invoked after a successful connections has been
  ## established with the IseDispatcher

  def self.init

    puts "The IseRubyModel has over-riden the Peerrb.init method" if $debug or $verbose

    ## Allocate space for the message
    @@stk_missile_detected = StkMissileDetected.new


    #########################################################
    ## Process the command line arguments
    ## expecting only 1 item in the following form:
    ##    --stk 138.209.69.248[:5001]

    @@stk_ip    = "138.209.69.248"  ## default: Dewayne's Windoze machine
    @@stk_port  = 5001

    $OPTIONS[:stk]        = nil
    $OPTIONS[:radar_file] = nil


    ## over-rid defaults with command line parameters

    ARGV.options do |o|

      o.on("-s", "--stk=ip[:port]", String, "IP address and port of STK visualizer")      { |$OPTIONS[:stk]| }
      o.on("-r", "--radars=file_name", String, "Filename that contains the radar definitions")      { |$OPTIONS[:radar_file]| }
      o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
      o.parse!

    end ## end of ARGV.options do

    puts "DEBUG: $OPTIONS[:stk] -=> #{$OPTIONS[:stk]}" if $debug or $verbose


    if $OPTIONS[:radar_file]
      require $OPTIONS[:radar_file]
    else
      $stderr.puts
      $stderr.puts "ERROR: No radards have been defined for the StkRadarDriver."
      $stderr.puts
      exit -1
    end


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
    ## Initialize the radar models

    @@radars = init_radars

    #    $radar_01 = @@radars[0]
    #    $radar_02 = @@radars[1]
    #    $radar_03 = @@radars[2]
    #    $radar_04 = @@radars[3]
    #    $radar_05 = @@radars[4]
    #    $radar_06 = @@radars[5]

#    $radar_02 = @@radars[3]   ## FIXME: in the UAE scenario there are 3 searchers and 3 trackers

    puts "\nNumber of radars defined: #{@@radars.length}"
    puts
    @@radars.each do |r|
      puts "name: #{r.name}"
      puts "\tclass:       #{r.class}"
      puts "\tposition:    #{r.position}"
      puts "\tazimuth:     #{r.azimuth_constraint}"
      puts "\televation:   #{r.elevation_constraint}"
      puts "\tfac_sop:     #{r.fac_sop}"
      puts "\tsop:         #{r.sop}"
      puts "\ttarget_type: #{r.target_type}"
      puts
      
      if "StaringRadar" == r.class.to_s
        @@trackers << r
      end
      
    end



    ########################################################
    ## Initialize a new STK scenario

    @@results_array = STK::send_msg( $STKSocket, "CheckScenario /" )

    unless @@results_array[1][0] == "1"   ## The returned string "1" means a scenario already is open
      @@results_array = STK::send_msg( $STKSocket, "New / Scenario #{@@scenario_name}" )
    end


    @@results_array = STK::send_msg( $STKSocket, "Epoch * #{$sim_time.stkfmt}" )
    @@results_array = STK::send_msg( $STKSocket, "SetAnimation * StartTime #{$sim_time.start_time.stkfmt} EndTime #{$sim_time.end_time.stkfmt} TimeStep #{$sim_time.step_seconds}" )

    @@results_array = STK::send_msg( $STKSocket, "ConControl / AsyncOff VerboseOff HighSpeedOff")


    STK::ack_on($STKSocket)

    @@results_array = STK::send_msg( $STKSocket, "ShowUnits * Connect")


    puts "\n STK Scenario: #{@@scenario_name}"
    puts "Results of ShowUnits:"

    @@results_array[1].each do |a_line|
      puts a_line
    end

    puts "-"*45



    ########################################################
    ## Setup Radar sensor visuals

    puts "DEBUG: Setup Radar Visuals in STK" if $debug_sim

    STK::ack_off($STKSocket) if STK::is_ack_on($STKSocket)

    @@radars.each do |a_radar|

      @@results_array = STK::send_msg( $STKSocket, "New / */Facility #{a_radar.name}" )
      @@results_array = STK::send_msg( $STKSocket, "SetPosition #{a_radar.fac_sop} Geodetic #{a_radar.position.join(' ')}" )
      @@results_array = STK::send_msg( $STKSocket, "VO #{a_radar.fac_sop} ScaleModel 25}" )
      
      @@results_array = STK::send_msg( $STKSocket, "New / #{a_radar.fac_sop}/Sensor #{a_radar.name}" )
      @@results_array = STK::send_msg( $STKSocket, "Define #{a_radar.sop} Rectangular #{a_radar.azimuth_delta} #{a_radar.elevation_delta}" )
      @@results_array = STK::send_msg( $STKSocket, "Location #{a_radar.sop} Fixed Cartesian 0.0 0.0 30.0" )  # position of the sensor on the platform
      @@results_array = STK::send_msg( $STKSocket, "VO #{a_radar.sop} Projection SpaceProjection #{a_radar.range[1]}" )
      @@results_array = STK::send_msg( $STKSocket, "VO #{a_radar.sop} Translucency 90" )
      @@results_array = STK::send_msg( $STKSocket, "SetConstraint #{a_radar.sop} Range Min #{a_radar.range[0]} Max #{a_radar.range[1]} " )

      case a_radar.class.to_s
      when "StaringRadar"       # SMELL: by convention the StaringRadar is a tracker
        @@results_array = STK::send_msg( $STKSocket, "DisplayTimes #{a_radar.sop} State AlwaysOff" )
        @@results_array = STK::send_msg( $STKSocket, "Graphics #{a_radar.sop} SetColor yellow" )
      else
        @@results_array = STK::send_msg( $STKSocket, "Graphics #{a_radar.sop} SetColor blue" )
        @@results_array = STK::send_msg( $STKSocket, "DisplayTimes #{a_radar.sop} State AlwaysOn" )
      end

      @@results_array = STK::send_msg( $STKSocket, "Point #{a_radar.sop} Schedule On")


    end ## end of @@radars.each do |a_radar|



    puts "DEBUG: Completed setup of visuals" if $debug_sim









    ##########################################################
    ## Subscribe to IseRubyModel-specific messages

    StkLaunchMissile.subscribe(StkRadarDriver.method(:add_to_missiles))
    StkTrackMissile.subscribe(StkRadarDriver.method(:add_to_tracks))


    ############################################################################
    ## Typical control messages used with the FrameController and TimeController

    #    InitEvent.subscribe(StkRadarDriver.method(:log_message))

    StartFrame.subscribe(StkRadarDriver.method(:start_frame))
    #    EndFrameRequest.subscribe(StkRadarDriver.method(:end_frame))
    #    EndFrameCommand.subscribe(StkRadarDriver.method(:end_frame))

    StatusRequest.subscribe(StkRadarDriver.method(:status_request))

    InitCase.subscribe(Peerrb::MonteCarlo.method(:init_case))
    EndCase.subscribe(Peerrb::MonteCarlo.method(:end_case))
    EndRun.subscribe(Peerrb::MonteCarlo.method(:end_run))

    AdvanceTime.subscribe(StkRadarDriver.method(:advance_time))





    Peerrb.rate=$sim_time.step_seconds


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

    $stderr.puts "Start Of Frame ================" if $debug_track

    $sim_time.advance_time

    $stderr.puts "  $sim_time.offset: #{$sim_time.offset}" if $debug_track

=begin  
    if $sim_time.offset > 28.2
      $debug      = true
      $debug_sim  = true
      $debug_stk  = true
      $stdout.flush
    end
=end 



    @@radars.each do |a_radar|
      unless "StaringRadar" == a_radar.class.to_s
        a_radar.advance_time( $sim_time.step_seconds )

        @@results_array = STK::send_msg( $STKSocket, "Point #{a_radar.sop} Schedule AddAzEl #{$sim_time.stkfmt} #{a_radar.azimuth} #{a_radar.elevation}" )
        @@results_array = STK::send_msg( $STKSocket, "SetConstraint #{a_radar.sop} AzimuthAngle Min #{a_radar.azimuth_constraint[0]} Max #{a_radar.azimuth_constraint[1]}" )
        @@results_array = STK::send_msg( $STKSocket, "SetConstraint #{a_radar.sop} ElevationAngle Min #{a_radar.elevation_constraint[0]} Max #{a_radar.elevation_constraint[1]}" )
      end
    end



    #########################
    ## Update the STK display

    STK::ack_off($STKSocket) if STK::is_ack_on($STKSocket)

    @@results_array = STK::send_msg( $STKSocket, "SetAnimation * CurrentTime #{$sim_time.stkfmt}" )




    ##############################################
    ## Look at each missile with the search radars

    if $sim_time.offset > 9.5  ## hard-coded for the counter-fire UAE sim

      $debug_track = false

      STK::ack_on($STKSocket) unless STK::is_ack_on($STKSocket)

      @@missiles.each do |a_missile|

        @@radars.each do |a_radar|

          unless "StaringRadar" == a_radar.class.to_s ## SMELL: by convention, staring radars are trackers

            if a_missile =~ a_radar.target_type
              track_label, range_to_target = radar_pings_missile?(a_radar, a_missile)
              unless track_label.nil?
                send_missile_detected_message(a_radar, a_missile, track_label, range_to_target)
              end
            end

          end ## end of unless "StaringRadar"

        end ## end of @@radars.each do |a_radar|

      end ## end of @@missiles.each do |a_missile|

      STK::ack_off($STKSocket) if STK::is_ack_on($STKSocket)

    end ## if $sim_time.offset > 44.0

    ########################################
    ## Point the Tracking Radar as necessary

    if @@tracks.length > 0

      STK::ack_off($STKSocket) if STK::is_ack_on($STKSocket)

      if @@next_track >= @@tracks.length
        @@next_track = 0
      end

      target_label      = @@tracks[@@next_track][0]
      target_position   = @@tracks[@@next_track][1]
      target_azimuth    = @@tracks[@@next_track][2]
      target_elevation  = @@tracks[@@next_track][3]
      target_tracking   = @@tracks[@@next_track][4]
      tracking_radar    = @@tracks[@@next_track][5]

      if $debug_track
        $stderr.puts "-"*45
        $stderr.puts "@@next_track: #{@@next_track}  target_label: #{target_label}"
        $stderr.puts "  target_position:  #{target_position}"
        $stderr.puts "  target_azimuth:   #{target_azimuth}"
        $stderr.puts "  target_elevation: #{target_elevation}"
        $stderr.puts "  target_tracking:  #{target_tracking}"
      end


      ############################
      ## Guess at current position

      ########################################################
      ## Initialize the next expected place to find the target

      target_next_azimuth     = target_azimuth
      target_next_elevation   = target_elevation

      #############################################
      ## Point the tracking Radar toward the target

      tracking_radar.azimuth     = target_azimuth
      tracking_radar.elevation   = target_elevation

      if target_tracking
        az_delta  = tracking_radar.azimuth_delta
        el_delta  = tracking_radar.elevation_delta
        az_min    = tracking_radar.azimuth_constraint[0]
        az_max    = tracking_radar.azimuth_constraint[1]
        el_min    = tracking_radar.elevation_constraint[0]
        el_max    = tracking_radar.elevation_constraint[1]
      else
        ## Cheat because STK's OnePointAccess DetailSummary report is screwed up
        radar_latlon   = cast(tracking_radar.position, LatLng)
        target_latlon  = cast(target_position, LatLng)
        tracking_radar.azimuth = radar_latlon.heading_to(target_latlon)

        ## Spread the beam, simulate a wider search patter
        az_delta  = 4.0 * tracking_radar.azimuth_delta
        el_delta  = 4.0 * tracking_radar.elevation_delta
        az_min    = tracking_radar.azimuth    - az_delta
        az_max    = tracking_radar.azimuth    + az_delta
        el_min    = tracking_radar.elevation  - el_delta
        el_max    = tracking_radar.elevation  + el_delta
      end

      if $debug_track
        $stderr.puts "  az_delta: #{az_delta}  el_delta: #{el_delta}"
        $stderr.puts "  az_min:   #{az_min}  az_max:   #{az_max}"
        $stderr.puts "  el_min:   #{el_min}  el_max:   #{el_max}"
        $stderr.puts "-"*15
        $stderr.puts "#{tracking_radar}"
        $stderr.puts "-"*15
      end

      unless tracking_radar.active?
        @@results_array = STK::send_msg( $STKSocket, "DisplayTimes #{tracking_radar.sop} State AlwaysOn" )
        tracking_radar.active = true
        $stderr.puts "Tracking Radar is ON"
      end

      STK::ack_off($STKSocket) if STK::is_ack_on($STKSocket)
      @@results_array = STK::send_msg( $STKSocket, "Point #{tracking_radar.sop} Schedule AddAzEl #{$sim_time.stkfmt} #{tracking_radar.azimuth} #{tracking_radar.elevation}" )
      @@results_array = STK::send_msg( $STKSocket, "Define #{tracking_radar.sop} Rectangular #{az_delta} #{el_delta}" )

      @@results_array = STK::send_msg( $STKSocket, "SetConstraint #{tracking_radar.sop} AzimuthAngle Min #{az_min} Max #{az_max}" )
      @@results_array = STK::send_msg( $STKSocket, "SetConstraint #{tracking_radar.sop} ElevationAngle Min #{el_min} Max #{el_max}" )


      ##################################################
      ## Does the radar see the target according to STK?


      stk_detected_target = update_target_position


      $stderr.puts "stk_detected_target: #{stk_detected_target}" if $debug_track



      #################################################
      ## Update the next expected azimuth and elevation

      $stderr.puts "EOP: will look here next: Az: #{@@tracks[@@next_track][2]}  El: #{@@tracks[@@next_track][3]}" if $debug_track

      @@next_track += 1



    end ## end of if @@tracks.length > 0
    ##########################################################################





    ######################
    ## Terminate the frame

    $stderr.puts "End Of Frame ================ $sim_time.offset: #{$sim_time.offset}" if $debug_track

    end_frame = EndFrame.new
    end_frame.publish

  end ## end of def self.start_frame



  #########################################################
  ## Update the position of the current target using
  ## OnePointAccess and Position commands; ignore azimuth
  ## data returned by OnePointAccess (STK version 8.1.2)

  def self.update_target_position

    $stderr.puts "entered update_target_position" if $debug_track

    target_detected = false ## default return value; only true if STK says "Yes"

    ##############################################################
    ## Ignore the azimuth returned by OnePointAccess - it is bogus

    a_missile             = @@tracks[@@next_track][0]
    target_position       = @@tracks[@@next_track][1]
    target_next_azimuth   = @@tracks[@@next_track][2]
    target_next_elevation = @@tracks[@@next_track][3]
    target_tracking       = @@tracks[@@next_track][4]
    tracking_radar        = @@tracks[@@next_track][5]


    #############################################
    ## Determine if STK can see it

    STK::ack_on($STKSocket) unless STK::is_ack_on($STKSocket)
    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{tracking_radar.sop} #{a_missile} Create" )
    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{tracking_radar.sop} #{a_missile} Compute DetailedSummary #{$sim_time.stkfmt}" )

    if $debug_track
      $stderr.puts "OnePointAccess #{tracking_radar.sop} #{a_missile}"
      $stderr.puts "#{@@results_array.pretty_inspect}"
    end

    if 'ACK' == @@results_array[0]

      target_detectable = @@results_array[1][0].split("\t")[1].strip

      if ( target_detectable.downcase =~ /yes/ )
        target_detected = true
      end
    end


    #################################################
    ## Process the DetailedSummary report
    ## regardless of the STK feelings about detection

    s               = a_missile.split('/')
    track_label     = s.last
    range_to_target = 0.0

    @@results_array[1].each do |rae|
      s = rae.split("\t")
      if s.length > 2
        puts "  #{s[1]} -=>  #{s[3]}" if $debug
        case s[1].downcase
        when /range/
          range_to_target = s[3].to_f
          $stderr.puts ".. got range:     #{range_to_target}" if $debug_sim or $debug_track
        when /azimuth/
          target_next_azimuth += s[3].to_f ## FIXME: * DEG_PER_RAD) - 360.0).abs -- STK returns bogus data
          $stderr.puts ".. got azimuth:   raw: #{s[3]}" if $debug_sim or $debug_track
        when /elevation/
          target_next_elevation =  s[3].to_f * DEG_PER_RAD
          $stderr.puts ".. got elevation: raw: #{s[3]} tne: #{target_next_elevation}" if $debug_sim or $debug_track
        end
      end
    end

    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{tracking_radar.sop} #{a_missile} Remove" )

    @@tracks[@@next_track][3] = target_next_elevation

    @@returned_results = STK::send_msg( $STKSocket, "Position #{a_missile} #{$sim_time.stkfmt}")

    if $debug_track
      $stderr.puts "Position #{a_missile}"
      $stderr.puts "#{@@returned_results.pretty_inspect}"
    end

    if 'ACK' == @@returned_results[0]
      mprda = @@returned_results[1][0].chomp.split(' ') ## missile position return data array

      target_position = [ mprda[0].to_f, mprda[1].to_f, mprda[2].to_f ]
      target_velocity = [ mprda[3].to_f, mprda[4].to_f, mprda[5].to_f ] # FIXME: check docs on results from STK

      puts "DEBUG: got missile position: #{target_position}  target_velocity: #{target_velocity}"  if $debug_sim

      ## Cheat because STK's OnePointAccess DetailSummary report is screwed up
      radar_latlon              = cast(tracking_radar.position, LatLng)
      target_latlon             = cast(target_position, LatLng)
      target_next_azimuth       = radar_latlon.heading_to(target_latlon)

      @@tracks[@@next_track][1] = target_position         ## comes from the Position report
      @@tracks[@@next_track][2] = target_next_azimuth     ## comes from the heading between the radar lla and the target lla
      @@tracks[@@next_track][3] = target_next_elevation   ## comes from the OnePointAccess report
      @@tracks[@@next_track][4] = true                    ## assume it is being tracked

      if $debug_track
        $stderr.puts "-=> pos: #{target_position}"
        $stderr.puts "-=> tna: #{target_next_azimuth}"
        $stderr.puts "-=> tne: #{target_next_elevation}"
      end

    else
      $stderr.puts "Did not return ACK on Position command" if $debug_track

      @@tracks[@@next_track][2] = target_next_azimuth     ## comes from the heading between the radar lla and the target lla
      @@tracks[@@next_track][3] = target_next_elevation   ## comes from the OnePointAccess report
      @@tracks[@@next_track][4] = false                   ## assume it is being tracked

    end





    $stderr.puts "leaving update_target_position  with target_detected: #{target_detected}" if $debug_track

    return target_detected

  end ## end of def self.update_target_position












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

  #############################################
  ## Add another missile to the missiles array

  def self.add_to_missiles(a_header, a_message)
    @@missiles << @@missile_class + '/' + a_message.label_.strip

    if $debug_sim
      puts "DEBUG: added new missile to watch list: #{a_message.label_}"
      #      $stderr.puts @@results_array.inspect
    end

  end


  #############################################
  ## Add aother missile to the missiles array

  def self.add_to_tracks(a_header, a_message)
  
    tracking_radar = @@trackers[rand(@@trackers.length)]    ## FIXME: Be smarter about assigning tracking radars

    @@tracks << [ @@missile_class + '/' + a_message.label_.strip, ## object path
      a_message.position_,  ## [1] last known position
      nil,                  ## [2] next projected azimuth
      nil,                  ## [3] next projected elevation
      false,                ## [4] Tracking missile
      tracking_radar        ## [5] radar instance assigned to track this target
    ]
    

    radar_position    = cast(tracking_radar.position, LatLng)
    missile_position  = cast(a_message.position_, LatLng)

    azimuth           = radar_position.heading_to(missile_position)


    # This is a crude flat-earth formula
    # elevation is expected to be above the round-earth target; but, the
    # width of the search beam should still sweep the target for a more
    # accurate fix.
    distance    = radar_position.distance_to(missile_position) * 1000.0   ## convert from km to meters
    altitude    = missile_position.alt
    elevation   = Math::atan( altitude / distance ) * DEG_PER_RAD


    @@tracks.last[2] = azimuth    
    @@tracks.last[3] = elevation
    @@tracks.last[4] = false
    

    if $debug_track
      puts "DEBUG: added new missile to track list: #{a_message.label_}"
      puts "  distance: #{distance}   altitude: #{altitude}   azimuth: #{azimuth}   elevation: #{elevation}"
      pp @@tracks
    end


  end ## end of def self.add_to_tracks(a_header, a_message)



  ##################################################
  def self.radar_pings_missile? (a_radar, a_missile)

    track_label     = nil
    range_to_target = 0.0


    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{a_radar.sop} #{a_missile} Create" )
    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{a_radar.sop} #{a_missile} Compute DetailedSummary #{$sim_time.stkfmt}" )


    if 'ACK' == @@results_array[0]

      td_array = @@results_array[1][0].split("\t")

      target_detectable = "no"  ## sometimes STK has not caught up
      target_detectable = td_array[1].strip if td_array.length > 1

      if ( target_detectable.downcase =~ /yes/ )

        s                 = a_missile.split('/')
        track_label       = s.last
        range_to_target   = 0.0

        @@results_array[1].each do |rae|
          s = rae.split("\t")
          if s.length > 2
            puts "  #{s[1]} -=>  #{s[3]}" if $debug
            if 'Range' == s[1]
              range_to_target = s[3].to_f
            end
          end
        end

        if $debug_track
          puts "Target detected?: #{track_label} by #{a_radar.name}"
          puts "  sim_time:  #{$sim_time.offset}"
          puts "  Azimuth:   #{a_radar.azimuth}"
          puts "  Elevation: #{a_radar.elevation}"
          puts "  Range:     #{range_to_target}"
        end

      end ## end of if ( target_detectable

    end ## end of if 'ACK' == @@results_array[0]

    @@results_array = STK::send_msg( $STKSocket, "OnePointAccess #{a_radar.sop} #{a_missile} Remove" )



    return track_label, range_to_target

  end ## end of def self.radar_pings_missile?




  #########################################################################################
  def self.send_missile_detected_message(a_radar, a_missile, track_label, range_to_target)


    @@returned_results = STK::send_msg( $STKSocket, "Position #{a_missile} #{$sim_time.stkfmt}")


    if 'ACK' == @@returned_results[0]
      mprda = @@returned_results[1][0].chomp.split(' ') ## missile position return data array

=begin
            @@lla_vehicle_state.unitID_   = m_cnt
            @@lla_vehicle_state.time_     = $sim_time.offset  # decimal seconds from start time of sim
            @@lla_vehicle_state.lla_      = [ mprda[0].to_f, mprda[1].to_f, mprda[2].to_f ]
            @@lla_vehicle_state.velocity_ = [ mprda[3].to_f, mprda[4].to_f, mprda[5].to_f ] # FIXME: check docs on results from STK
            @@lla_vehicle_state.attitude_ = [ mprda[6].to_f, mprda[7].to_f, mprda[8].to_f ] # FIXME: check docs on results from STK
            @@lla_vehicle_state.publish if $publish_stk_missile_positions
=end

      target_position = [ mprda[0].to_f, mprda[1].to_f, mprda[2].to_f ]

      puts "DEBUG: got missile position: #{target_position}" if $debug_sim

    else
      target_position = [ 0.0, 0.0, 0.0]

      puts "DEBUG: Could not get the missile position; using: #{target_position}" if $debug_sim
    end

    @@stk_missile_detected.label_     = track_label
    @@stk_missile_detected.position_  = target_position
    @@stk_missile_detected.range_     = range_to_target
    @@stk_missile_detected.azimuth_   = a_radar.azimuth
    @@stk_missile_detected.elevation_ = a_radar.elevation

    @@stk_missile_detected.publish

    $stdout.flush if $debug

  end ##  end of def self.send_missile_detected_message




end ## module StkRadarDriver

puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose


