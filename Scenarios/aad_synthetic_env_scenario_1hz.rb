#############################################################################
###
##  Name:   aad_synthetic_env_scenario_1hz.rb
##  Desc:   Advanced Air Defense Synthetic Environment
##          This program queries STK every second for missile positions.  Those
##          position reports are sent on the IseCluster as LLA_Vehicle_State messages.
##
##
## TODO: Support multi-radar scenarios; use radar access reports to get visability to targets.
#


puts "Entering: #{File.basename(__FILE__)}" if $debug

$verbose     = false

$debug       = false
$debug_sim   = false
$debug_stk   = false

require 'aadse_utilities'



require 'SimpleJMessage'
require 'SpaceTrack'
require 'AirTrack'
require 'LandPointPPLI'




path_to_me = Pathname.new(File.expand_path(File.dirname(__FILE__)))

########################################################################
## Ensure that AADSE System-wide environment varables are set correctly
unless ENV['ISE_ROOT'] and ENV['AADSE_ROOT']
  msg  = "Correct the problem described below and try again"
  msg << "#{$ENDOFLINE}\tThe ISE setup_symbols file has not been sourced." unless ENV['ISE_ROOT']
  msg << "#{$ENDOFLINE}\tThe AADSE setup_symbols file has not been sourced." unless ENV['AADSE_ROOT']
  fatal_error msg
end

$AADSE_ROOT        = Pathname.new(ENV['AADSE_ROOT'])


###################################################################
## Establish the defaults for a SimpleJ wrapped SpaceTrack Message

$sjm_st = SimpleJMessage.new SpaceTrack

$sjm_st.simplej_header.sequence_num_  = 0
$sjm_st.simplej_header.transit_time_  = 0

=begin                                                  # unitID == one-hundred in decimal)
$sjm_st.link16_message.tn_ls_3_bit_   = 0b000     # "0" special Link16 3-bit encoding only supports 0..7
$sjm_st.link16_message.tn_mid_3_bit_  = 0b000     # "0"
$sjm_st.link16_message.tn_ms_3_bit_   = 0b001     # "1"
$sjm_st.link16_message.tn_ls_5_bit_   = 0b10011   # 0x13; // "M" -=> Missile
$sjm_st.link16_message.tn_ms_5_bit_   = 0b10111   # 0x17; // "R" -=> Red
=end

$sjm_st.link16_message.track_number_reference_ = Link16Message.encode_track_id('RM100')


###################################################################
## Establish the defaults for a SimpleJ wrapped AirTrack Message


$sjm_air = SimpleJMessage.new AirTrack

$sjm_air.link16_message.track_number_reference_ = Link16Message.encode_track_id('RA100')
$sjm_air.link16_message.air_platform_           =  0 # No Statement
#$sjm_air.link16_message.air_platform_           =  5 # Recon
#$sjm_air.link16_message.air_platform_           = 10 # Transport
#$sjm_air.link16_message.air_platform_           = 16 # AWACS
#$sjm_air.link16_message.air_platform_           = 44 # Cruise Missile

$sjm_air.link16_message.identity_amplifying_descriptor_        = 0  ## 0=yellow(pending); 3=blue; 6=red

#####################################################################
## Establish the defaults for a SimpleJ wrapped LandPointPPLI Message


$sjm_lpppli = SimpleJMessage.new LandPointPPLI




$link16_hub = PortPublisher.new(ENV['AADSE_GATEWAY_10'])




#################################################
## Build the STK Scenario

aadse_stk_dir         = Pathname.new($AADSE_ROOT) + "STK"
stk_scneario_builder  = aadse_stk_dir + "stk_scenario_generator.rb"

cmdline_path = Pathname.new($AADSE_ROOT) + "test" + "data" + "S_Generator"

ssb_cmdline = "-v"  # "-v --root " + cmdline_path.to_s

=begin
  -v, --[no-]verbose               Print Actions
  -f, --file=../IDP/scenario.xml   IDP Laydown XML file name
  -x, --xref=idp_to_stk_xref.rb    IDP to STK CrossReference File Name
=end



puts "Building STK Scenario ---------========>>"
rc = system("ruby #{stk_scneario_builder} #{ssb_cmdline}")

unless rc
  $stderr.puts
  $stderr.puts "ERROR: Unable to execute the STK scenario builder."
  $stderr.puts "       path: #{stk_scneario_builder}"
  $stderr.puts
  exit -1
end

puts "="*45
puts "STK Scenario has been built and is running: #{rc}"

sleep 5   # waste some time because the loop_closer sometimes crashes at launch.



###################################################################################
## Kill any left over simulation stand-alone applications

rc = system("kill_sim_apps")






###################################################################################
## Launch the AADSE specific cache-logger program

aadse_event_logger_dir  = Pathname.new($AADSE_ROOT) + "event_logger"
cache_logger            = aadse_event_logger_dir + "cache_logger.rb"

cl_cmdline = "&> cache_logger.log"

puts "Starting the cache logging process ---------========>>"

rc = system("ruby #{cache_logger} #{cl_cmdline} &")

puts "="*45
puts "Cache Logging has been launched is running: #{rc}"




=begin
###############################################################################
## PopUp Message Box

window_title    = "SimControl Says..."
button_text     = "Press This Button After Evan Presses His"
message_text    = "Tell Evan to Push the button"
xmessage_parms  = "-center -fg white -bg red"

rc = system("xmessage #{xmessage_parms} -buttons \"#{button_text}\" \"#{message_text}\" -title \"#{window_title}\"")
=end










##############################################################################
## Launch the loop_closer

loop_closer = aadse_stk_dir + "loop_closer.rb"

lc_cmdline  = " &> loop_closer.log"

rc = system("ruby #{loop_closer} #{lc_cmdline} &")

unless rc
  $stderr.puts
  $stderr.puts "ERROR: Unable to launch the Loop Closer."
  $stderr.puts "       path: #{loop_closer}"
  $stderr.puts
  exit -1
end


puts "Loop Closer has been started and is running: #{rc}"
puts "="*45

sleep 5   # waste some time waiting for loop_closer to open for business





##############################################################################
## Launch the GUI for engagement manager stand in

sim_control = $AADSE_ROOT + "engmngr/stand_in/GUI/emsi_gui.rb"

sc_cmdline  = "&> emsi_gui.log"

rc = system("ruby #{sim_control} #{sc_cmdline} &")

unless rc
  $stderr.puts
  $stderr.puts "WARNING: Unable to launch the SimControl GUI"
  $stderr.puts "         path: #{sim_control}"
  $stderr.puts
end


puts "SimControl has been started and is running: #{rc}"
puts "="*45




#############################################################
## launch the engagement manager stand-in

engagement_manager_stand_in = $AADSE_ROOT + "engmngr/stand_in/engagement_manager_standin.rb"

emsi_cmdline = "&> emsi.log"


rc = system("ruby #{engagement_manager_stand_in} #{emsi_cmdline} &")

unless rc
  $stderr.puts
  $stderr.puts "ERROR: Unable to launch the engagement_manager_stand_in."
  $stderr.puts "       path: #{engagement_manager_stand_in}"
  $stderr.puts
  exit -1
end


puts "Engagement Manager (stand-in) has been started and is running: #{rc}"
puts "="*45


##########################################################
## Now start up the web applications

launch_web_apps = "launch_web_apps"

rc = system(launch_web_apps)








##################################################
puts "... Linking this process to STK" if $verbose


$STK_IP           = ENV['STK_IP']  # '10.9.8.2'
$STK_PORT         = ENV['STK_PORT']# 5001
$STK_CONID        = ENV['USER']


link_to_stk

$STK_BASEDIR = Pathname.new($STK_HOMEDIR.to_s + "\\aadse_stk\\")

puts "...... Base Directory set to: #{$STK_BASEDIR}" if $verbose




##################################################################
## Get the SimTime from STK - the master clock for this sim.

ra = putstk "GetAnimationData * TimePeriod"

st_array = ra[1][0].split(',')

st_array.each_index do |x|
  st_array[x].gsub!('"', '').strip
end

$sim_time = SimTime.new( 1.0, st_array[0], st_array[1], true )  ## true indicates that STK is the time lord

if $verbose
  puts "...... Success!  SimTime is:"
  puts "......... StartTime: #{$sim_time.start_time.stkfmt}"
  puts "......... EndTime:   #{$sim_time.end_time.stkfmt}"
end



###################################################
# Get Connect Units
ra = putstk "ShowUnits * Connect"

connect_units = ra[1][0].strip.split("\n")

puts "... STK Connect Units of Measure" if $verbose
connect_units.each do |a_line|
  puts "...... #{a_line}"  if $verbose
end



######################################################
## Define the laydown junk as global hashes

$stk_missile_sops = Array.new
$red_missile_sops = Array.new
$blue_missile_sops= Array.new

$missile_objects  = Hash.new

def get_stk_missile_sops

  sncm_ra = putstk('ShowNames * Class Missile')

  if 'ACK' == sncm_ra[0] and 0 < sncm_ra[1].length

    $stk_missile_sops = sncm_ra[1][0].split
    $red_missile_sops = []
    $blue_missile_sops= []

    $stk_missile_sops.each do |sop|
      name = sop.split('/').last
      $red_missile_sops   << sop if name.is_red_force?    ## per naming convention RM = Red Missile
      $blue_missile_sops  << sop if name.is_blue_force?   ## ... BM = Blue Missile
      $missile_objects[name] = SharedMemCache.get name
    end

  end

end ## end of def get_stk_missile_sops






######################################################
## Define the laydown junk as global hashes

$stk_aircraft_sops  = Array.new
$stk_facility_sops  = Array.new
$red_aircraft_sops  = Array.new
$blue_aircraft_sops = Array.new
$blue_launcher_sops = Array.new

$aircraft_objects   = Hash.new

#########################
def get_stk_aircraft_sops

  snca_ra = putstk('ShowNames * Class Aircraft')

  if 'ACK' == snca_ra[0] and 0 < snca_ra[1].length

    $stk_aircraft_sops = snca_ra[1][0].split
    $red_aircraft_sops = []
    $blue_aircraft_sops= []

    $stk_aircraft_sops.each do |sop|
      name = sop.split('/').last
      $red_aircraft_sops   << sop if name.is_red_force?    ## per naming convention RM = Red Missile
      $blue_aircraft_sops  << sop if name.is_blue_force?   ## ... BM = Blue Missile
      $aircraft_objects[name] = SharedMemCache.get name
    end

  end

end ## end of def get_stk_aircraft_sops



#########################
def get_stk_launcher_sops

  sncf_ra = putstk('ShowNames * Class Facility')

  if 'ACK' == sncf_ra[0] and 0 < sncf_ra[1].length

    $stk_facility_sops = sncf_ra[1][0].split
    $blue_launcher_sops= []

    $stk_facility_sops.each do |sop|
      $blue_launcher_sops  << sop if 'BL' == sop.split('/').last[0,2]    ## ... BL = Blue Launcher
    end

  end

end ## end of def get_stk_launcher_sops





######################################
## require all the messages to be sent


# require 'LLA_Vehicle_State'

#$lla_vehicle_state   = LLA_Vehicle_State.new


require 'EndEngagement'
require 'EndRun'

############################################################
## instantiate a new scenario with a single line description

s = IseScenario.new "AADSE Simulation 1Hz"
s.step = 1.0    ## time step in decimal seconds

s.at(0.0) do
  puts "IseScenario at zero seconds."
  get_stk_missile_sops
  get_stk_aircraft_sops

  EM::add_periodic_timer( 1.0 ) do  ## code block executes every 1.0 seconds
    update_sim_time_from_stk        ## STK is the Master Clock
  end

end


#############################################################
## Update list of missiles from STK every 10 seconds

# could disable this block since all red missiles and all red/blue aircraft are known

s.every(10.0) do
  puts "10 seconds - update sops"
  get_stk_missile_sops
  get_stk_aircraft_sops
end


############################
## Ask STK for position info
## lla in degrees and meters
## vv (velocity vector) degrees/second; meters/second
## av (attitude vector) always zeros

def get_position_of(an_sop)

  ra  = putstk("Position #{an_sop} #{$sim_time.stkfmt}")

#  $stderr.puts "Position ra: #{ra.inspect}"

  return [nil, nil, nil] unless 'ACK' == ra[0]

  raa = ra[1][0].split

  lla = [raa[0].to_f,  raa[1].to_f,  raa[2].to_f]
  vv  = [raa[3].to_f,  raa[4].to_f,  raa[5].to_f]

  return [lla, vv, [0.0, 0.0, 0.0]]
end

############################
#$m_cnt            = 100
#$missile_unit_id  = Hash.new

def unit_id_of_missile(a_str)
  return a_str.split('_').last.to_i
#  return $missile_unit_id[a_str] if $missile_unit_id.include?(a_str)
#  $m_cnt += 1
#  $missile_unit_id[a_str] = $m_cnt
#  return $m_cnt
end


############################
def update_sim_time_from_stk

  ra=putstk "GetAnimationData * CurrentTime"

  if 'ACK' == ra[0]
    ts = ra[1][0]
    $sim_time.sim_time = Time.parse ts[1,ts.length-2]
  else
    nil
  end

end


=begin
#############################################################
## Remove dead STK objects as necessary

$unload_at = []

s.every(1.0) do
    unload_things unless $unload_at.empty?
end

=end


###########################################################
## Log relationship of real-time to sim-time

last_time = Time.now
now_time  = Time.now
duration  = now_time - last_time

s.every(1.0) do
  now_time  = Time.now
  duration  = now_time - last_time
  last_time = now_time
  $stderr.puts "RT-step: #{duration}\tsim_time: #{s.now}"
end


###########################################################
## Get positions of all Missiles

$last_st_time = $sim_time.sim_time

s.every(1.0) do

  unless $last_st_time == $sim_time.sim_time ## don't do anything if the simulation is paused


    $sjm_st.simplej_header.transit_time_  = $sim_time.offset

    $sjm_st.link16_message.minute_        = Integer($sim_time.offset / 60)
    $sjm_st.link16_message.second_        = Integer($sim_time.offset) - 60 * $sjm_st.link16_message.minute_






    $stk_missile_sops.each do |sop|
    
      unless "none" == sop.downcase
    
        name    = sop.split('/').last
                
        unit_id = name.split('_').last
        # unit_id is expected to be a 3 character numberic string with no 8 or 9 digits just 0..7
        unit_id = '0' + unit_id while 3 > unit_id.length
        track_id  = "#{name[0,2]}#{unit_id}"


        if track_id.length > 5
          system('banner ERROR')
          log_this "-==> From #{__FILE__} == #{track_id} == #{name[0,2]} + #{unit_id}"
        end

  # FIXME: Need equivalent for SpaceTrack
        $sjm_st.link16_message.identity_ = 0  ## 0=yellow(pending); 3=blue; 6=red
        $sjm_st.link16_message.identity_ = 3  if name.is_blue_force?
        $sjm_st.link16_message.identity_ = 6  if name.is_red_force?

        rv              = get_position_of sop

  #      $stderr.puts "name: #{name}  sop: #{sop}  rv: #{rv.inspect}"

  #      $sjm_st.link16_message.tn_ms_3_bit_   = unit_id[0].to_i
  #      $sjm_st.link16_message.tn_mid_3_bit_  = unit_id[1].to_i
  #      $sjm_st.link16_message.tn_ls_3_bit_   = unit_id[2].to_i

        $sjm_st.link16_message.track_number_reference_ = Link16Message.encode_track_id(track_id)

        lla_coord   = cast(rv[0], LlaCoordinate)
        ecef_coord  = lla_coord.to_ecef   # NOTE: ecef units in meters



        x           = (ecef_coord.x / 0.3048).to_i   # x,y,z in meters converting to feet
        y           = (ecef_coord.y / 0.3048).to_i
        z           = (ecef_coord.z / 0.3048).to_i
        vx          = 0
        vy          = 0
        vz          = 0

        $sjm_st.simplej_header.sequence_num_ += 1

        $sjm_st.link16_message.x_position_  = SpaceTrack.scale(x, 0.1, 0x800000).to_i
        $sjm_st.link16_message.y_position_  = SpaceTrack.scale(y, 0.1, 0x800000).to_i
        $sjm_st.link16_message.z_position_  = SpaceTrack.scale(z, 0.1, 0x800000).to_i

        $sjm_st.link16_message.x_velocity_  = SpaceTrack.scale(vx, 1.0/3.33, 0x2000).to_i
        $sjm_st.link16_message.y_velocity_  = SpaceTrack.scale(vy, 1.0/3.33, 0x2000).to_i
        $sjm_st.link16_message.z_velocity_  = SpaceTrack.scale(vz, 1.0/3.33, 0x2000).to_i

        $sjm_st.pack_message
        $link16_hub.send_data $sjm_st.out

      end ## end of unless "None" == sop

    end ## end of $stk_missile_sops.each do |sop|

  end ## end of unless $last_time == $sim_time.sim_time

  $last_st_time = $sim_time.sim_time

end ## end of s.every(1.0) do






###########################################################
## Get positions of all Aircraft

$last_air_time == $sim_time.sim_time

s.every(1.0) do

  unless $last_air_time == $sim_time.sim_time ## don't do anything if the simulation is paused


    $sjm_air.simplej_header.transit_time_  = $sim_time.offset

    $sjm_air.link16_message.minute_ = Integer($sim_time.offset / 60)    # convert seconds to minutes
    $sjm_air.link16_message.hour_   = Integer($sim_time.offset / 3600)  # convert seconds to hours


    $stk_aircraft_sops.each do |sop|

      unless "none" == sop.downcase

        name = sop.split('/').last
        launch_time = $aircraft_objects[name].launch_time
        impact_time = $aircraft_objects[name].impact_time

        if (launch_time < $sim_time.sim_time)  and  ($sim_time.sim_time < impact_time)
          rv = get_position_of sop
          lla = rv[0]
        else
          lla = nil
        end

        unless lla.nil?

          name    = sop.split('/').last

          unit_id = name.split('_').last
          # unit_id is expected to be a 3 character numberic string with no 8 or 9 digits just 0..7
          unit_id = '0' + unit_id while 3 > unit_id.length

          track_id = "#{name[0,2]}#{unit_id}"

          platform_type = name.split('_')[0]
          platform_type = platform_type[2,platform_type.length-2]

          $sjm_air.link16_message.identity_amplifying_descriptor_ = 0  ## 0=yellow(pending); 3=blue; 6=red
          $sjm_air.link16_message.identity_amplifying_descriptor_ = 3  if name.is_blue_force?
          $sjm_air.link16_message.identity_amplifying_descriptor_ = 6  if name.is_red_force?



  #$stderr.puts "pos_of aircraft -=> name: #{name}  track_id: #{track_id}  platform_type: #{platform_type}  sop: #{sop}  rv: #{rv.inspect}"


          case platform_type
            when 'UAV' then
              $sjm_air.link16_message.air_platform_           =  5 # Recon
            when 'C' then
              $sjm_air.link16_message.air_platform_           = 10 # Transport
            when 'R' then
              $sjm_air.link16_message.air_platform_           = 16 # AWACS
            when 'CM' then
              $sjm_air.link16_message.air_platform_           = 44 # Cruise Missile
            else
              $sjm_air.link16_message.air_platform_           =  0 # No Statement
          end


          $sjm_air.simplej_header.sequence_num_ += 1

          $sjm_air.link16_message.track_number_reference_ =  Link16Message.encode_track_id(track_id)

  #        $sjm_air.link16_message.latitude_       = Integer(lla[0] / 0.00008583)    # An Integer count of minutes
  #        $sjm_air.link16_message.longitude_      = Integer(lla[1] / 0.00008583)
  #        $sjm_air.link16_message.altitude_25_ft_ = Integer(lla[2] * 0.131233596 )  # convert meters to feet then scale in 25 foot increments

          $sjm_air.link16_message.set_lla(lla)

          $sjm_air.pack_message

  #        $stderr.puts $sjm_air.out.to_hex

          $link16_hub.send_data $sjm_air.out

        end ## end of unless lla.nil?

      end ## end of unless "none" == sop.downcase

    end ## end of $stk_missile_sops.each do |sop|

  end ## end of unless $last_time == $sim_time.sim_time

  $last_air_time = $sim_time.sim_time

end ## end of s.every(1.0) do






####################################################################
## Report positions of all launchers

$last_lpppli_time == $sim_time.sim_time

s.every(30.0) do

  unless $last_lpppli_time == $sim_time.sim_time ## don't do anything if the simulation is paused

    get_stk_launcher_sops

    $blue_launcher_sops.each do |sop|

      rv  = get_position_of sop
      lla = rv[0]

      unless lla.nil?

      # TODO: send lpppli
        name    = sop.split('/').last
        unit_id = name.split('_').last.to_i

        $sjm_lpppli.link16_message.voice_call_sign_char4of4_ = unit_id
        $sjm_lpppli.link16_message.set_lat_lon lla

        $sjm_lpppli.pack_message

        $link16_hub.send_data $sjm_lpppli.out

      end ## end of unless lla.nil?

    end ## end of $blue_launcher_sops.each do |sop|


  end ## end of unless $last_lpppli_time == $sim_time.sim_time

  $last_lpppli_time == $sim_time.sim_time

end ## end of s.every(30.0) do








#############################
s.every(5.0) do
  $stdout.flush
end


s.list


=begin

This snippet sends an lla_vehicle_state message on ISE
given the rv returned from the call to STK for position info.

      lla             = rv[0]
      velocity_vector = rv[1]
      attitude_vector = rv[2]
      unless lla.nil?
        $lla_vehicle_state.unitID_   = unit_id_of_missile(name)
        $lla_vehicle_state.time_     = $sim_time.offset  # decimal seconds from start time of sim
        $lla_vehicle_state.lla_      = lla
        $lla_vehicle_state.velocity_ = velocity_vector
        $lla_vehicle_state.attitude_ = attitude_vector
        $lla_vehicle_state.publish
      end


=end




## The End
##################################################################



