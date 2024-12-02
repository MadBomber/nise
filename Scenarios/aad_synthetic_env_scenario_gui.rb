#############################################################################
###
##  Name:   aad_synthetic_env_scenario_gui.rb
##  Desc:   Advanced Air Defense Synthetic Environment
##          The scenario files required below are event driven
##


s = IseScenario.new "GUI for AADSE Engagement Manager"

require 'systemu'


$verbose            = true
$debug              = false
$debug_stk_message  = false
$debug_cmd          = $debug_stk_message
$debug_stk          = $debug_stk_message
$debug_stk_dryrun   = false



require 'pathname'        ## lib: cross platform file paths
require 'optparse'        ## lib: used for the command line
require 'ostruct'         ## lib: OpenStruct class

require 'Parameters'      ## parser for the SBPS parameters file


scenario_name = 'September_Demo_UAE'

def die a_string
  puts
  puts "FATAL #{a_string}"
  c=caller
  c.each {|cc| puts cc}
  exit -1
end

# Initialize STK_IP and PORT from system environment variables or use defaults

$STK_IP      = ENV['STK_IP']
$STK_IP    ||= '127.0.0.1'

$STK_PORT    = ENV['STK_PORT']
$STK_PORT  ||= 5001

$STK_CONID   = ENV['USER']       ## On Linux
$STK_CONID ||= ENV['USERNAME']   ## On Windoze

$IDP_XML_PATHNAME = Pathname.new '../IDP/scenario.xml'


#############################################################################################
## Process the Command line Parameters

#################
# default options

options = OpenStruct.new

options.debug         = $debug     ## Set debug mode, $DEBUG is global $debug is local
options.verbose       = $verbose   ## Set berbose mode, $VERBOSE is global, $verbose is local
options.stk_ip        = $STK_IP
options.stk_port      = $STK_PORT
options.stk_conid     = $STK_CONID
options.scenario_name = 'September_Demo_UAE'
options.time_offset   = 13         ## Offset in minutes from beginning of scenario to start this thing

o = OptionParser.new do |o|

  script_name = File.basename($0)

  o.set_summary_indent('  ')
  o.banner =    "Usage: #{script_name} [options]"
  o.define_head "AADSE STK Scenario Runner"
  o.separator   ""
  o.separator   "Mandatory arguments to long options are mandatory for short options too."

  o.on("-d", "--debug",    "Set debug mode")            { |v| options.debug        = v; $debug   = true }
  o.on("-v", "--[no-]verbose", "Print Actions")         { |v| options.verbose      = v; $verbose = true }

  o.on("-n", "--name=#{options.scenario_name}", "STK Scenario Name") { |v| options.scenario_name = v }

  o.on("-t", "--time=#{options.time_offset}", Integer, "Offset (whole minutes) from Scenario Start") { |v| options.time_offset = v }

  o.separator ""
  o.on("-i", "--ip='#{$STK_IP}'",       "STK IP Address")  { |v| options.stk_ip = v }
  o.on("-p", "--port='#{$STK_PORT}'",   "STK Port Number") { |v| options.stk_ip = v.to_i }
  o.on("-c", "--conid='#{$STK_CONID}'", "STK Connect ID")  { |v| options.stk_ip = v }

  o.separator ""
  o.on_tail("-h", "--help", "Show this help message.") { |v| options.help = v }

  begin
    o.parse!
  rescue Exception => e
    $stderr.puts "ERROR: Command-line Parse Error: #{e}"
    is_good         = false
    options.debug   = true
    options.verbose = true
    options.help    = true
    return_value    = -1
  end

end

if $debug
  require 'pp'
  puts
  puts "The command-line options structure:"
  pp options
  puts
  puts "The remaining command-line arguments from ARGV:"
  pp ARGV
  puts
end

if options.help
  puts
  puts o

  puts <<HERE

Purpose
=======

The purpose of this program is to interact with an STK scenario that has
allready been created.  This is a demonstration of how to insert
dynamic ballistic interceptors into a running STK scenario.

HERE
  exit
end


##############################
## Validate command line stuff

$STK_IP     = options.stk_ip
$STK_PORT   = options.stk_port
$STK_CONID  = options.stk_conid

is_good = true




die "Command line parameters have errors." unless is_good

#############################################################################################

if $verbose
  puts "Command line parameters:"
  puts "  debug .......... #{options.debug}"
  puts "  verbose ........ #{options.verbose}"
  puts "  stk_ip ......... #{options.stk_ip}"
  puts "  stk_port  .... . #{options.stk_port}"
  puts "  stk_conid ...... #{options.stk_conid}"
  puts "  scenario_name .. #{options.scenario_name}"
  puts "  time_offset .... #{options.time_offset}"
end




require 'StkMessage'    ## STK library and support tools
require 'SimTime'       ## Simulation time library





#################################################
puts "... Linking to STK" if $verbose

link_to_stk

#################################################
puts "... Getting STK Home Directory" if $verbose

ra = putstk "GetSTKHomeDir /"
$STK_HOMEDIR = Pathname.new ra[1][0].strip

# All relative file names/paths have $STK_BASEDIR as their root
$STK_BASEDIR = Pathname.new($STK_HOMEDIR.to_s + 'aadse_stk')

puts "...... Base Directory set to: #{$STK_BASEDIR}" if $verbose

putstk "OpenHtmlOnLoad / On"

putstk("Unload / *") if "1" == putstk("CheckScenario /")[1][0]


###################################################################
sc_filename_str = $STK_BASEDIR.to_s + "\\#{options.scenario_name}.sc"

puts "...... Loading Scenario file: #{sc_filename_str}" if $verbose

ra=putstk "Load / Scenario \"#{sc_filename_str}\""

if 'NACK' == ra[0]
  $stderr.puts
  $stderr.puts "ERROR: STK Scenario file not found."
  $stderr.puts "       STK IP .... #{$STK_IP}"
  $stderr.puts "       STK PORT .. #{$STK_PORT}"
  $stderr.puts "       File ...... #{sc_filename_str}"
  $stderr.puts
  exit -1
end

ra = putstk "GetAnimationData * TimePeriod"

st_array = ra[1][0].split(',')

st_array.each_index do |x|
  st_array[x].gsub!('"', '').strip
end

$sim_time = SimTime.new( 1.0, st_array[0], st_array[1] )

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


#################################################
puts "... Getting all STK Object Names" if $verbose

ra = putstk "AllInstanceNames /"

stk_objects = ra[1][0].split

pp stk_objects if $verbose

stk_scenario_sop = stk_objects[0]


###############################################
puts "... Extracting red missiles" if $verbose

ra = putstk "ShowNames * Class Missile"

pp ra

$red_missile_sops = ra[1][0].split

red_missile_sops.each_index do |x|
  $red_missile_sops[x] = nil if $red_missile_sops[x].include?('Interceptor')
end

$red_missile_sops.compact!


#################################################
puts "... Extracting blue launchers" if $verbose

ra = putstk "ShowNames * Class Facility"

$blue_launchers_sops = ra[1][0].split

$blue_launchers_sops.each_index do |x|

  $blue_launchers_sops[x] = nil unless $blue_launchers_sops[x].include?('/LT_')

end

$blue_launchers_sops.compact!

$lue_launchers = Hash.new

$blue_launchers_sops.each do |bl_sop|

  bl      = OpenStruct.new
  bl.sop  = bl_sop
  bl.name = bl_sop.split('/').last
  
  ra = putstk "Position #{bl_sop}"
  
  if 'NACK' == ra[0]
    puts "ERROR: can't get a position for a facility; that is not good."
    bl.lla  = [0.0, 0.0, 0.0]
  else
    a       = ra[1][0].split
    bl.lla  = [a[0].to_f, a[1].to_f, a[2].to_f]
  end
  
  $blue_launchers[bl.name] = bl

end







#
##
####
######
##########
################
#########################
##########################################
######################################################



##################################################
## require all the messages to be sent or received

require 'StkLaunchMissile'    ## equivalent to a FireOrder
require 'RequestForFire'

require 'EndEngagement'
require 'EndRun'



############################################################
## instantiate a new scenario with a single line description

lead_secs   = 2*60
tof_secs    = lead_secs.to_f / 2.0

pac3_cnt    = 1

$unload_at  = Array.new   ## [sop, time]

s.at(0.0) do
  IseScenario.subscribe(RequestForFire)

  $sim_time.sim_time = $sim_time.start_time + options.time_offset * 60  ## convert minutes to seconds

  #putstk 'VO * ViewFromTo Normal From */AreaTarget/Dubai'
  ra = putstk 'Animate * Pause'
  ra = putstk 'Animate * Reset'
  ra = putstk "SetAnimation * CurrentTime #{$sim_time.sim_time.stkfmt}"

end



###############################################
## At the first ISE tick start the STK Scenario

s.at(0.1) do
  ra = putstk 'Animate * Start Forward'
  #ra = putstk 'Animate * Start End'
end




###########################################
## Every second unload destroyed objects



s.every(1.0) do
    unload_things unless $unload_at.empty?
end






s.every(1.0) do

  unless red_missile_sops.empty?
    puts "get the current animation time"
    ra=putstk "GetAnimationData * CurrentTime"

    ts = ra[1][0]
    ct = Time.parse ts[1,ts.length-2]
    puts ct

    $red_missile_sops.each_index do |x|
    
      rm_sop  = red_missile_sops[x]
      rm_name = rm_sop.split{'/'}.last
      
      pac3_name = "Interceptor_#{pac3_cnt}"
      
      engaged = engage_target_with(rm_sop, $blue_launchers['LT_1'].sop, pac3_name)
      
      if engaged
        pac3_cnt += 1
        puts "... #{rm_name} is being engaged with #{pac3_name}"
        $red_missile_sops[x] = nil
      else
        puts "... #{rm_name} can not be engaged at this time."
      end
    
    end ## end of red_missile_sops.each_ibdex do |x|
    
    $red_missile_sops.compact!

  end ## end of unless

end ## s.every(1.0)




















########################################################
## Event-based tasks

my_engagements      = []  ## array of targets names engaged
my_dne              = []  ## array of targets not engaged
fire_unit_assigned  = 0   ## the fire unit assigned to the current engagement

s.on(:RequestForFire) do

  target_label    = s.message(:RequestForFire)[1].label_
  target_position = s.message(:RequestForFire)[1].target_position_
  
  puts "Received a RequestForFire"
  puts "  Target: #{target_label}   at: #{target_position}"
  
  unless  my_engagements.include?(target_label) or
          my_dne.include?(target_label)

    puts "DEBUG: Displaying xmessage window" if $debug
    
    button_list = ""
    blue_launchers.each do |bl|
      button_list += bl[:name] + ","
    end
    button_list += "Shoot w/Best Fit,Do Not Engage"
    fu_value_range = 101 .. 100+blue_launchers.length

    status, mil_action, error_msg = systemu("xmessage -nearmouse -buttons '#{button_list}' -timeout 30 -print 'Request For Fire Received: #{target_label} #{target_position}'")
    mil_action.chomp!
  
    if $debug  
      puts "DEBUG: xmessage window closed with following parameters set ..."
      puts "       status:     #{status.inspect}"
      puts "       exitstatus: #{status.exitstatus}"
      puts "       mil_action: #{mil_action}"
      puts "       error_msg:  #{error_msg}"
    end
  
    if 'Do Not Engage' ==  mil_action
      my_dne << target_label
    else
      my_engagements << target_label
      
      case status.exitstatus
        when 0, fu_value_range.max+1    ## 0 means the dialog box timed out
          fire_unit_assigned = rand(blue_launchers.length)    ## assign a random fire unit
        when fu_value_range
          fire_unit_assigned = status.exitstatus - 101        ## remember array index start at zero
      end
      s.set(:FireOrder)
    end
    
  end
  
end

#####################
s.on(:FireOrder) do

    target_label    = s.message(:RequestForFire)[1].label_
    target_position = s.message(:RequestForFire)[1].target_position_
  
    if $debug
      puts "DEBUG: A Fire Order has been simulated"
      puts "  Target: #{target_label}   at: #{target_position}"
      puts "  Fire Unit Assigned: #{fire_unit_assigned} -- #{blue_launchers[fire_unit_assigned][:name]}"
    end
  
    a_message = StkLaunchMissile.new
    a_message.label_            = "cf_#{my_engagements.length}"
    a_message.launch_position_  = blue_launchers[fire_unit_assigned][:position]
    a_message.target_position_  = target_position
    a_message.publish
  
    if $debug
      puts "DEBUG: StkLaunchMissile has been published"
      puts "       Label: #{a_message.label_}"
    end

end

s.list  if $debug_sim


## The End
##################################################################


