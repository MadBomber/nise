#####################################################################
###
##  File:  StkMessage.rb
##  Desc:  The base class for binding generic STK 'connect' messages
##         into one thing.
##
## TODO: Need to flesh this out; could make this part of the STK library

require 'STK'
require 'time'
require 'time_mods'
require 'pathname'
require 'PkTable'
require 'LlaCoordinate'

$debug_stk_message = false unless defined?($debug_stk_message)

##################
# helper methods #
##################


def fullpath_to(some_filename)

  return nil unless some_filename

  case some_filename.class.to_s
    when 'String' then
      some_pathname = Pathname.new some_filename
    when 'Pathname' then
      some_pathname = some_filename
    else
      return nil
  end

  some_pathname = $STK_BASEDIR + some_pathname if some_pathname.relative?

  return some_pathname

end ## end of def fullpath_to


############################################################################
class StkMessage

  attr_accessor :connect_msg
  attr_accessor :connection_id

  #####################
  def initialize(conid=$STK_CONID)
    @connection_id = conid
    @connect_msg = []
  end

  ##################
  def add(a_str=nil)
    if a_str
      case a_str.class.to_s
        when 'String'
          @connect_msg += a_str.split("\n")
        when 'Array'
          @connect_msg += a_str
        else
          puts "wanted either a String or an Array"
      end
    end
  end

  ########
  def to_s
    a_str=""
    @connect_msg.each do |cm|
      a_str << "#{cm}\n"
    end
    return a_str
  end

  ###########
  def publish(print_command=$debug_stk_message)
    returned_results = []
    @connect_msg.each do |cm|
      puts "#{@connection_id} -=> #{cm}" if print_command or $debug_stk_dryrun
      returned_results << STK::process_connect_command(@connection_id, cm)  unless $debug_stk_dryrun
      puts "results -=> #{returned_results.last.inspect}" if print_command
    end
    return returned_results
  end

  ##########################
  def replace(a_hash)

    @connect_msg.length.times do |x|
        a_hash.each_pair do |k, v|
            @connect_msg[x][k] = v
        end
    end

  end

  ########
  def list
    puts "#{self}"
  end


end ## end of StkMessage


########################
## STK Helper Methods ##
########################

def putstk(a_string)
  if $debug_stk_dryrun
    puts "putstk\t" + a_string
    ra = ['NACK', []]
  else
    ra = STK::send_msg($STK_CONID, a_string)
  end
  return ra
end


###############
def link_to_stk
  unless ( STK::connect_to_stk( $STK_PORT, $STK_IP, $STK_CONID, 30 ) )
    die "ERROR: Unable to connect:", Get_Socket_Result(), " \n"
  end
  
  ra = putstk "GetSTKHomeDir /"
  
  $STK_HOMEDIR = Pathname.new ra[1][0] if ra[0] == 'ACK'
  $STK_BASEDIR = $STK_HOMEDIR

end


###################################
def init_stk(name='ISE', extra=nil)


  die "$sim_time has not been set."       unless defined?($sim_time)
  die "$STK_IP has not been set."         unless defined?($STK_IP)
  die "$STK_PORT has not been set."       unless defined?($STK_PORT)
  die "$STK_CONID has not been set."      unless defined?($STK_CONID)


  ###################################
  # Establish Connection to STK
  unless $debug_stk_dryrun
    link_to_stk
  end


  ############################################################
  puts "... Unload existing Scenario as necessary" if $verbose

  ra = putstk("CheckScenario /")

  if "1" == ra[1][0]
    ra = putstk("Unload / *")
    if 'ACK' == ra[0]
      puts "...... sucessful" if $verbose
    else
      puts "...... failed" if $verbose
    end
  else
    puts "...... not necessary" if $verbose
  end




  ############################################
  # Create the Scenario Name and set the times
  ism = StkMessage.new

  ism.add "New / Scenario #{name}"
  ism.add "SetTimePeriod * #{$sim_time.start_time.stkfmt} #{$sim_time.end_time.stkfmt}"
  ism.add "SetEpoch * #{$sim_time.start_time.stkfmt}"
  ism.add "SetAnimation * StartTime #{$sim_time.start_time.stkfmt} EndTime #{$sim_time.end_time.stkfmt}#{' ' + extra unless extra.nil?}"
  ism.add "GetSTKHomeDir /"

  retval = ism.publish


  unless $debug_stk_dryrun
    $STK_HOMEDIR = Pathname.new retval[4][1][0] if retval[4][0] == 'ACK'

    die "GetSTKHomeDir failed." unless defined?($STK_HOMEDIR)
  else
    $STK_HOMEDIR = Pathname.pwd
  end
  
  return retval

end ## end of def init_stk

########################################################################################
def create_facility(  lla,          ## latitude, longitude in decimal degrees, altitude in meters
                      name,
                      scale = 0.5,
                      color = $YELLOW_STK_COLOR,
                      model = nil
                    )

  
  cf = StkMessage.new

  cf.add "New / Facility #{name}"

  sop = "*/Facility/#{name}"

  cf.add "SetPosition #{sop} Geodetic #{lla.join(' ')}"
  cf.add "VO #{sop} Model File \"#{fullpath_to(model)}\""  unless model.nil?
  cf.add "VO #{sop} ScaleLog #{scale}"
  cf.add "Graphics #{sop} SetColor #{color} Marker"
  cf.add "Graphics #{sop} SetColor #{color} Label"

  cf.publish

  return sop

end ## end of def create_airfield


########################################################################################
def create_airfield(  lla,
                      scale = 0.5,
                      color = $YELLOW_STK_COLOR,
                      model = $STK_HOMEDIR + 'STKData/VO/Models/Land/airport.mdl'
                    )

  sop = create_facility(lla, 'Airfield', scale, color, model)

  return sop

end ## end of def create_airfield


########################################################################################
def create_aircraft(  name,             ## A name for this object
                      flight_plan=nil,  ## an array [latitude,  (decimal degrees)
                                        ## longitude,           (decimal degrees)
                                        ## altitude,            (decimal meters)
                                        ## xxx,        xxx.class => Time or Float (if float its velocity in Kph)
                                        ## yyy]        yyy.class => Float (accelleration) meters/sec^2

                      color = $RED_STK_COLOR,
                      scale = 0.5,
                      model = nil)    ## FIXME: Add path to a generic airplane model



  die "No flight plan for #{name}" if flight_plan.nil?

  ca = StkMessage.new

  ca.add("New / Aircraft #{name}")

  sop = "*/Aircraft/#{name}"

  ca.add("VO #{sop} ScaleLog #{scale}")
  ca.add("Graphics #{sop} SetColor #{color} Marker")
  ca.add("Graphics #{sop} SetColor #{color} Label")
  ca.add("VO #{sop} Model File \"#{fullpath_to(model)}\"")    unless model.nil?


  case flight_plan.class.to_s
    when 'Array' then
      length_flight_plan = flight_plan.length

      if 'Array' == flight_plan.class.to_s and length_flight_plan > 0

        wp_cnt = 0
        flight_plan.each do |wp|  ## way-point

          wp_cnt += 1

          length_wp = wp.length

          if length_wp >= 4 and length_wp <= 5

            case wp[3].class.to_s
              when 'Time' then
                ca.add("AddWaypoint #{sop} DetVelFromTime #{wp[0..2].join(' ')} #{wp[3].stkfmt}")
              else
                velocity = wp[3] * 0.000277777778   ## convert from Kph to kilometers per sec
                if 4 == wp.length
                  ca.add("AddWaypoint #{sop} DetTimeAccFromVel #{wp[0..2].join(' ')} #{velocity}")
                else
                  acceleration = wp[4]   ## meters per sec^2
                  ca.add("AddWaypoint #{sop} DetTimeFromVelAcc #{wp[0..2].join(' ')} #{velocity} #{acceleration}")
                end
            end ## end of case wp[3].class.to_s

          else
            puts
            puts "ERROR: Bad waypoint data for #{sop}"
            puts "       Waypoint No. #{wp_cnt}: #{wp.join(', ')}"
            puts
          end

        end ## end of flight_plan.each do

      end ## end of if length_flight_plan > 0

    else

      ca.add("SetState */Aircraft/#{name} File \"#{fullpath_to(flight_plan)}\"")

  end ## case

  ca.publish
  
  return sop

end ## end of def create_aircraft


################################################
def create_awacs(name, flight_plan, color, scale, model)

  sop = create_aircraft(  name,
                    flight_plan, # flight_plan
                    color=$BLUE_STK_COLOR,
                    scale=0.5,    # scale
                    model='AWACS\e-3a_sentry_awacs.mdl')
  
  radar_rpm           = 60.0      # revolutions per minute
  radar_range         = 300_000.0 # meters
  radar_az_beam_width = 2.0       # degrees
  radar_el_beam_width = 45.0      # degrees
  
  awacs = StkMessage.new

  awacs.add("New / #{sop}/Sensor #{name}")
  sop = "#{sop}/Sensor/#{name}"

  awacs.add("Define #{sop} Rectangular #{radar_az_beam_width} #{radar_el_beam_width}")
  awacs.add("Point #{sop} Spinning 0 90 45 Continuous #{radar_rpm} 0")
  awacs.add("SetConstraint #{sop} Range Max #{radar_range}")
  
  awacs.publish
  
  return sop
    
end ## end of def create_awacs



################################################
def create_uav( name, flight_plan,
                color = 6, scale = 0.5,
    model=$STK_HOMEDIR + 'STKData/VO/Models/Air/uav.mdl')

  sop = create_aircraft(name, flight_plan, color, scale, model)

  return sop
  
end

##########################################################
def create_cruse_missile( name, flight_plan,
                          color = $RED_STK_COLOR, scale = 0.5,
    model=$STK_HOMEDIR + 'STKData/VO/Models/Missiles/tomahawk.mdl')


  sop = create_aircraft(name, flight_plan, color, scale, model)

  return sop

end

alias :create_cruise_missile :create_cruse_missile

#######################################################
def create_helicopter( name, flight_plan,
                       color = $RED_STK_COLOR, scale = 0.5,
    model=$STK_HOMEDIR + 'STKData/VO/Models/Air/helicopter.mdl')

  sop = create_aircraft(name, flight_plan, color, scale, model)

  return sop

end

#############################################################################
def create_rotating_radar(lla_location, name, rpm, beam_width, range)

  crr = StkMessage.new

  fac_sop = create_facility(lla_location, name)

  crr.add "New / #{fac_sop}/Sensor #{name}"

  sop = "#{fac_sop}/Sensor/#{name}"

  crr.add "Define #{sop} Rectangular #{beam_width.join(' ')}"
  crr.add "Point #{sop} Spinning 0 90 90 Continuous #{rpm} 0"
  crr.add "SetConstraint #{sop} Range Min #{range[0]} Max #{range[1]}"

  crr.publish

  return sop

end ## end of def create_rotating_radar


#########################################################
def area_target_circle( a_name   = "undefined",
                        an_lla   = [0.0, 0.0, 0.0],
                        a_color  = $BLUE_STK_COLOR,
                        a_radius = 1500,
                        a_line_width = 4.0)
  
  case an_lla.class.to_s
    when 'Array' then
      lla = an_lla
    when 'LlaCoordinate' then
      lla = [an_lla.lat, an_lla.lng, an_lla.alt]
    else
      die "Parameter an_lla is wrong class"
  end
  
  atgt = StkMessage.new
  sop = "*/AreaTarget/#{a_name}"

  atgt.add "New / AreaTarget #{a_name}"
  atgt.add "SetBoundary #{sop} Ellipse #{a_radius} #{a_radius} 0"
  atgt.add "SetPosition #{sop} Geodetic #{lla.join(' ')}"
  atgt.add "VO #{sop} BorderWall Show On UseTranslucency On Translucency 1 TopAltRef Terrain BottomAltRefValue 0"
  atgt.add "Graphics #{sop} LineWidth #{a_line_width}"
  atgt.add "Graphics #{sop} SetColor #{a_color} Marker"
  atgt.add "Graphics #{sop} SetColor #{a_color} Polygon"
  atgt.add "Graphics #{sop} SetColor #{a_color} Label"
  atgt.publish
  
  return sop
  
end


########################################
def create_pac3_launcher(a_name, an_lla)

  sop = create_facility( an_lla, a_name, 1.75,
                   5,   # blue
                   'Patriot_Launcher\Patriot_Launcher.mdl')

  return sop

end

# TODO: Get STK Model for Thaad and GemT launchers then flesh out the following methods:
alias :create_thaad_launcher :create_pac3_launcher
alias :create_gemt_launcher :create_pac3_launcher


##########################################################
def create_missile( name,
                    launch_lla,
                    impact_lla,
                    launch_time=$sim_time.sim_time,
                    trajectory_shaper='ApogeeAlt 40000',
                          color = $RED_STK_COLOR, scale = 0.5,
    model=$STK_HOMEDIR + 'STKData/VO/Models/Missiles/scud4.mdl')

  cm = StkMessage.new
  sop = "*/Missile/#{name}"

  cm.add "New / Missile #{name}"
  cm.add "Missile #{sop} Trajectory #{launch_time.stkfmt} 1 LnLatGeod  #{launch_lla.join(' ')} #{trajectory_shaper} ImLatGeod #{impact_lla.join(' ')}"
  cm.add "VO #{sop} ScaleLog #{scale}"
  cm.add "VO #{sop} ModelList Add  #{launch_time.stkfmt} \"#{fullpath_to(model)}\""
  cm.add "VO #{sop} ModelList Use On"
  cm.add "VO #{sop} Pass TrajLead None"
  cm.add "VO #{sop} Pass TrajTrail All"
  cm.add "VO #{sop} Pass GrndLead None"
  cm.add "VO #{sop} Pass GrndTrail None"

  ["Label", "Marker", "GroundTrack"].each do |item|
    cm.add "Graphics #{sop} SetColor #{color} #{item}"
  end

  cm.publish
  
  return sop

end


##############################################################################################
## returns true meaning an interceptor was created or false meaning can not engage

$unload_at = []

def engage_target_with(target_sop, launcher_sop, interceptor_name, lead_secs=180, tof_secs=90, pk_table=nil)

  ###########################################
  ## Get hte current position of the Launcher
  
  target_name   = target_sop.split('/').last
  launcher_name = launcher_sop.split('/').last
  
  unless $blue_launchers.include?(launcher_name)
    ra = putstk "Position #{launcher_sop}"
    
    if 'NACK' == ra[0]
      puts "ERROR: can't get a position for the launcher; that is not good."
      raise "Can not get a position fix on the launcher."
    else
      a       = ra[1][0].split
      launch_lla  = [a[0].to_f, a[1].to_f, a[2].to_f]
    end
  else
    launch_lla = $blue_launchers[launcher_name].lla
  end
  
  launch_lla_coord = LlaCoordinate.new(launch_lla[0], launch_lla[1], launch_lla[2])
  
  ##################################
  ## get the current simulation time
  
  ra=putstk "GetAnimationData * CurrentTime"

  ts = ra[1][0]
  ct = Time.parse ts[1,ts.length-2]

  pip_time = ct + lead_secs

  #############################################
  ## Get the position of the target at pip_time
  
  ra = putstk "Position #{target_sop} #{pip_time.stkfmt}"

  if 'NACK' == ra[0]
    puts "... don't know where it will be in #{lead_secs} seconds."
    raise "Can not engage this target."
  end      

  a             = ra[1][0].split
  pip_lla       = [a[0].to_f, a[1].to_f, a[2].to_f]
  pip_lla_coord = LlaCoordinate.new(pip_lla[0], pip_lla[1], pip_lla[2])

  ###################################################
  ## Get the range_to the target from the launch site
  
  range_to = launch_lla_coord.distance_to(pip_lla_coord, :units => :kilo) * 1000.0 # convert to meters

  ###############################################
  ## Get hte Pk for that range and altitude

  prob_kill = pk_slice.at(range_to, pip_lla_coord.alt)

  if 'Float' == prob_kill.class.to_s
    if prob_kill <= 1.0
      prob_kill = Integer(prob_kill * 100.0) 
    else
      prob_kill = Integer(prob_kill) 
    end
  else
    prob_kill = Integer(prob_kill)
  end
  
  
  # normailize to 0..100
  prob_kill = 100   if prob_kill > 100
  prob_kill = 0     if prob_kill < 0
  
  r_factor = rand(101)  ## rand returns integer between 0..upper-1
  
  miss_it = false
  miss_it = true    if r_factor > prob_kill

  log_this("Range: #{range_to}  Alt: #{pip_lla_coord.alt} Pk: #{prob_kill} r_factor: #{r_factor}  miss_it: #{miss_it}")


  #######################################
  ## Calculate the Launch Time
    
  launch_time       = pip_time - tof_secs

  launch_time       += rand(5)+1  if miss_it    ## if it is a miss, launch 5 seconds too late
  
  trajectory_shaper = "TOF #{tof_secs}"
  model             = $STK_HOMEDIR + 'STKData/VO/Models/Missiles/patriot_missile.mdl'
  
  create_missile( interceptor_name,
                  launch_lla, pip_lla, launch_time, trajectory_shaper,
                  color = $BLUE_STK_COLOR, scale = 0.5, model)

  unless miss_it
    explosion_model = $STK_HOMEDIR + "STKData/VO/Models/Misc/explosion.mdl"
    
    interceptor_sop = "*/Missile/#{interceptor_name}"
    
    puts "adding explosion to #{interceptor_name} and #{target_name}"
    
    ra = putstk("VO #{interceptor_sop} ModelList Add #{pip_time.stkfmt} \"#{explosion_model}\"")
    ra = putstk("VO #{target_sop} ModelList Add #{pip_time.stkfmt} \"#{explosion_model}\"")

    $unload_at << [interceptor_sop, pip_time]
    $unload_at << [target_sop, pip_time + 2]
  end


  return (not miss_it)  # return hit_it value

end ## end of def engage_target_with



################################
def remove_from_unload_at(entry)

  $unload_at = SharedMemCache.get('unload_at')

  return false if $unload_at.empty?

  pos_inx = $unload_at.index(entry)
  return false if pos_inx.nil?

  $unload_at.delete_at(pos_inx)
  
  SharedMemCache.set('unload_at', $unload_at)

  return true

end

#################
def unload_things

  $unload_at = SharedMemCache.get('unload_at')

  return if $unload_at.empty?
  
  pack_it = false
  
  ra=putstk "GetAnimationData * CurrentTime"

  ts = ra[1][0]
  ct = Time.parse ts[1,ts.length-2]
  
  $unload_at.each_index do |x|
  
    sop       = $unload_at[x][0]
    pip_time  = $unload_at[x][1]

    if ct >= pip_time
      puts "#{sop.split('/').last} has been destroyed." if $verbose
      ra = putstk "unload / #{sop}"
      pack_it = true
      $unload_at[x] = nil
    end  

  end
  
  if pack_it
    $unload_at.compact! 
    SharedMemCache.set('unload_at', $unload_at)
  end
  
end ## end of def unload_things



#############################################################
## Query STK for the current position of an sop

def get_position_of(thing_sop, date_time=$sim_time.sim_time)

  ra = putstk "Position #{thing_sop} #{date_time.stkfmt}"
  
#  pp ra

  if 'NACK' == ra[0]
    return nil
  else
    a       = ra[1][0].split
    return LlaCoordinate.new(a[0].to_f, a[1].to_f, a[2].to_f)
  end

end ## end of def get_position_of



###########################################################
def get_future_position_of(thing_sop, future_date_time=nil)

  log_this "get_future_position_of"

  case future_date_time.class.to_s
  when 'Time' then
    # do nothing
  when 'NilClass' then
    future_date_time = $sim_time.sim_time + $lead_secs
  when 'Fixnum' then
    future_date_time = $sim_time.sim_time + future_date_time
  when 'Float' then
    future_date_time = $sim_time.sim_time + future_date_time
  else
    raise "Invalid class for future_date_time: #{future_date_time.class} Value: #{future_date_time}"
  end

  lla = get_position_of(thing_sop, future_date_time)

  return lla

end ## end of def get_future_position_of



#########################################################
## STK is the Master Clock for the AADSE Simulation
def get_stk_current_time

  ra=putstk "GetAnimationData * CurrentTime"
  ts = ra[1][0]
  
  if 'ACK' == ra[0]
    $sim_time.sim_time = Time.parse ts[1,ts.length-2]
  else
    $stderr.puts "=== STK is not sharing Time ==="
  end
  
  return $sim_time.sim_time

end ## end of def get_stk_current_time



#########################################################
## STK is the Master Clock for the AADSE Simulation
def get_time_period(sop='*', wait=false)


  if wait
  
    trys = 3
    ra = ['any',[]]
    
    while ra[1].empty? and trys > 0 do
      sleep 1                                 # give STK some time to think
      ra = putstk("GetTimePeriod #{sop}")
      trys -= 1
    end
  else
    ra = putstk("GetTimePeriod #{sop}")  
  end
  
  if 'ACK' == ra[0]
    begin
      aa = ra[1][0].split(',')
    rescue
      puts "DEBUG: ========== slow STK error ============="
      puts "\tsop: #{sop}"
      puts "\tra: #{ra.inspect}"
      return []
    end
    
#    puts "ra: #{ra.inspect}"
#    puts "aa: #{aa.inspect}"
    
    a_str = aa[0]

    return [] unless a_str


    start_time = Time.parse(a_str[1,a_str.length-2])
    end_time   = start_time
    a_str = aa[1]
    
    return [] unless a_str
    
    
    end_time   = Time.parse(a_str[1,a_str.length-2]) - 0.12 # backup a little to ensure a Position report from STK

    return [start_time, end_time]
  end
  
  return []

end ## end of def get_time_period



  ###################################
  def add_stk_explosion(sop, at_time)
    log_this("Adding explosion to #{sop} at #{at_time}")
    explosion_model = $STK_HOMEDIR + "STKData/VO/Models/Misc/explosion.mdl"
    ra = putstk("VO #{sop} ModelList Add #{at_time.stkfmt} \"#{explosion_model}\"")
    return 'ACK' == ra[0]
  end


  ###################################
  def delete_stk_explosion(sop, at_time)
    log_this("Deleting explosion from #{sop} at #{at_time}")
    ra = putstk("VO #{sop} ModelList Delete #{at_time.stkfmt}")
    return 'ACK' == ra[0]
  end



