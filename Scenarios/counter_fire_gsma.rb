#############################################################################
###
##  Name:   counter_fire_gsma.rb
##
##  Desc:   An example scenario to illustrate the use of a timed scenario.
##          The implacement locations are the Greater Seoul Metro Area (GSMA)
##
##          This scenario can be used in combination with the
##          counter_fire_gsma_gui.rb file running within a different
##          instance of the ScenarioDriver.
##

puts "Entering: #{File.basename(__FILE__)}" if $debug


$debug       = false
$debug_sim   = true
$debug_stk   = true


require 'SimTime'

$sim_time = SimTime.new(  0.1,
                          '27 Jul 1953 11:00:00.000',
                          '27 Jul 1953 11:30:00.000' )


$code_words = %w(one two three four five six seven eight nine ten eleven twelve thirteen fourteen fiveteen sixteen seventeen eighteen nineteen twenty)
$code_words << %w(twenty-one twenty-two twenty-three twenty-four twenty-five twenty-six twenty-seven twenty-eight twenty-nine thirty)

######################################################
## Define the laydown junk as global hashes

$blue_radars     = Hash.new
$blue_launchers  = Hash.new

$red_launchers       = Hash.new
$red_rocket_impacts  = Hash.new
$red_ram             = Hash.new
$red_ram_impacts     = Hash.new

$red_rocket_tracks   = []
$red_ram_tracks      = []

########################
## Blue Force Laydown ##
########################


$blue_radars["radar_01"] = [38.052438, 127.124346, 0.0]
$blue_radars["radar_02"] = [37.81265882971723, 126.8774007941036, 0.0]

pp $blue_radars
puts "-"*25

$blue_launchers["cf_launcher_01"] = [37.23796232773378, 126.9975666493282, 0.0]
$blue_launchers["cf_launcher_02"] = [37.23949057276692, 126.9981968541871, 0.0]
$blue_launchers["cf_Launcher_03"] = [37.81265882971723, 126.8774007941036, 0.0]


pp $blue_launchers
puts "-"*25

#######################
## Red Force Laydown ##
#######################

######################
# Missile Launch Sites

$red_launchers["icbm_launcher_01"] = [40.85472222243736, 129.6661111110708, 0.0]
$red_launchers["scud_launcher_01"] = [38.99122141330254, 125.8894662354888, 0.0]
$red_launchers["scud_launcher_02"] = [38.62422337660961, 126.6715297954489, 0.0]
$red_launchers["scud_launcher_03"] = [38.53658900163454, 127.1633607204643, 0.0]
$red_launchers["scud_launcher_04"] = [38.62213572419216, 126.6781890036083, 0.0]

pp $red_launchers
puts "-"*25


#################
# Missile Impacts

$red_rocket_impacts["icbm_impact_01"] = [35.68948801842536, 139.6917059954399, 0.0]
$red_rocket_impacts["icbm_impact_02"] = [35.15108479501102, 128.6404605170973, 0.0]
$red_rocket_impacts["scud_impact_01"] = [37.23980610750843, 127.0054782462626, 0.0]
$red_rocket_impacts["scud_impact_02"] = [37.2381276076832,  127.0082915545978, 0.0]

pp $red_rocket_impacts
puts "-"*25

$red_rocket_tracks  = [$red_launchers["icbm_launcher_01"], $red_rocket_impacts["icbm_impact_01"]]
$red_rocket_tracks << [$red_launchers["icbm_launcher_01"], $red_rocket_impacts["icbm_impact_02"]]

puts "ICBM:"
pp $red_rocket_tracks
puts "-"*25

$red_launchers.each_pair do |rl_k, rl_v|
  if rl_k.include?('scud')
    $red_rocket_impacts.each_pair do |ri_k, ri_v|
      if ri_k.include?('scud')
        $red_rocket_tracks << [rl_v, ri_v]
      end
    end
  end
end

puts "ICBM and SCUD:"
pp $red_rocket_tracks
puts "-"*25


##################
# RAM Launch Sites

$red_ram["nkfa_01"] = [38.40276424475872, 127.1878884842183,  0.0]
$red_ram["nkfa_02"] = [38.39837355099311, 126.9517693622188,  0.0]
$red_ram["nkfa_03"] = [38.36227105768338, 126.7267403625344,  0.0]
$red_ram["nkfa_04"] = [38.21128879965826, 126.6359446346108,  0.0]
$red_ram["nkfa_05"] = [38.21399829292647, 126.3917395781019,  0.0]
$red_ram["nkfa_06"] = [38.16399592013168, 126.126834470563,   0.0]
$red_ram["nkfa_07"] = [38.15830209012676, 126.1109482520017,  0.0]
$red_ram["nkfa_08"] = [38.15539490106193, 126.0861699900485,  0.0]
$red_ram["nkfa_09"] = [38.15087260392178, 126.0582371656701,  0.0]
$red_ram["nkfa_10"] = [38.14280499558249, 126.03528979759,    0.0]

pp $red_ram
puts "-"*25

###################
# RAM Impact Points

$red_ram_impacts["nkfa_impact_01"] = [38.05284887872471, 127.132443803648,  0.0]
$red_ram_impacts["nkfa_impact_02"] = [38.0494793414543,  127.127180791273,  0.0]
$red_ram_impacts["nkfa_impact_03"] = [38.05453077998276, 127.1213289676571, 0.0]
$red_ram_impacts["nkfa_impact_04"] = [38.0509762803922,  127.1127314940301, 0.0]

pp $red_ram_impacts
puts "-"*25

$red_ram.each do |fire_unit|
  $red_ram_impacts.each do |target|
    $red_ram_tracks << [fire_unit, target]
  end
end


pp $red_ram_impacts
puts "-"*25

######################################
## require all the messages to be sent


require 'StkLaunchMissile'
require 'StkMissileDetected'
require 'StkTrackMissile'
require 'RequestForFire'

require 'EndEngagement'
require 'EndRun'

############################################################
## instantiate a new scenario with a single line description

s = IseScenario.new "Missile Counter-fire GSMA"
s.step = 10.0    ## time step in decimal seconds

s.at(0.0) do
  $detected_cnt = Hash.new
  IseScenario.subscribe(StkMissileDetected)
end

last_time = Time.now
now_time  = Time.now
duration  = now_time - last_time

s.every(1.0) do
  now_time  = Time.now
  duration  = now_time - last_time
  last_time = now_time
  $stderr.puts "RT-step: #{duration}\tsim_time: #{s.now}"
end

########################################################
## Event-based tasks

s.on(:StkMissileDetected) do

  track_label = s.message(:StkMissileDetected)[1].label_
  
  $detected_cnt[track_label] = 0 unless  $detected_cnt.include? track_label

  if track_label.include?('icbm') or track_label.include?('scud') 
    $detected_cnt[track_label] += 1  
    s.remark "== Target #{track_label} Detected Count: #{$detected_cnt[track_label]}"
  end

  if 3 == $detected_cnt[track_label]
    a_message = RequestForFire.new
    a_message.label_            = track_label
    a_message.target_position_  = $red_launchers["icbm_launcher_01"]
    a_message.publish
    s.remark "== Published RequestForFire Message =="
    s.remark "#{a_message}"
  end
  
end



my_tracks=[]
s.on(:StkMissileDetected) do
  
  unless my_tracks.include? s.message(:StkMissileDetected)[1].label_
  
    $stderr.puts "Tasking Tracking Radar to acquire: #{s.message(:StkMissileDetected)[1].label_}"
  
    my_tracks << s.message(:StkMissileDetected)[1].label_
    a_message = StkTrackMissile.new
    a_message.label_     = s.message(:StkMissileDetected)[1].label_
    a_message.position_  = s.message(:StkMissileDetected)[1].position_
    a_message.range_     = s.message(:StkMissileDetected)[1].range_
    a_message.publish
    
  end
  
end

=begin

###################################################################
s.on(:boom) do
  $stderr.puts
  $stderr.puts "######   #######  #######  #     #  "
  $stderr.puts "#     #  #     #  #     #  ##   ##  "
  $stderr.puts "#     #  #     #  #     #  # # # #  "
  $stderr.puts "######   #     #  #     #  #  #  #  "
  $stderr.puts "#     #  #     #  #     #  #     #  "
  $stderr.puts "#     #  #     #  #     #  #     #  "
  $stderr.puts "######   #######  #######  #     #  "
  $stderr.puts
  system("ls -alF")
end

########################################################
## Periodic-tasks

count_down = 10
s.every(1.0, 5.0, 20.0) do
  if count_down > 0
    count_down -= 1
    $stderr.puts count_down
  end
  if 0 == count_down
    count_down = -999
    s.set :boom
  end
end

=end

#########################################################
## Time-based tasks

s.step = 2.0

s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "icbm_01"
  a_message.launch_position_  = $red_launchers["icbm_launcher_01"]
  a_message.target_position_  = $red_rocket_impacts["icbm_impact_01"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end






s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "icbm_02"
  a_message.launch_position_  = $red_launchers["icbm_launcher_01"]
  a_message.target_position_  = $red_rocket_impacts["icbm_impact_02"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
  
  
  s.set :second_icbm_launched
end




s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "scud_01"
  a_message.launch_position_  = $red_launchers["scud_launcher_01"]
  a_message.target_position_  = $red_rocket_impacts["scud_impact_01"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end



s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "scud_02"
  a_message.launch_position_  = $red_launchers["scud_launcher_02"]
  a_message.target_position_  = $red_rocket_impacts["scud_impact_02"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end


s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "scud_03"
  a_message.launch_position_  = $red_launchers["scud_launcher_03"]
  a_message.target_position_  = $red_rocket_impacts["scud_impact_01"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end



s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "scud_04"
  a_message.launch_position_  = $red_launchers["scud_launcher_04"]
  a_message.target_position_  = $red_rocket_impacts["scud_impact_02"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end



# s.at(30.0) do
#   er = EndRun.new
#   er.publish
# end

#################################################################
## RAM Threats

=begin
s.now   = 49.0
s.step  =  1.0




s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "nkfa_01"
  a_message.launch_position_  = $red_ram["nkfa_01"]
  a_message.target_position_  = $red_ram_impacts["nkfa_impact_01"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end


s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "nkfa_02"
  a_message.launch_position_  = $red_ram["nkfa_02"]
  a_message.target_position_  = $red_ram_impacts["nkfa_impact_01"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end

s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "nkfa_03"
  a_message.launch_position_  = $red_ram["nkfa_03"]
  a_message.target_position_  = $red_ram_impacts["nkfa_impact_02"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end

s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "nkfa_04"
  a_message.launch_position_  = $red_ram["nkfa_04"]
  a_message.target_position_  = $red_ram_impacts["nkfa_impact_03"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end



s.at(:next) do
  a_message = StkLaunchMissile.new
  a_message.label_            = "nkfa_05"
  a_message.launch_position_  = $red_ram["nkfa_05"]
  a_message.target_position_  = $red_ram_impacts["nkfa_impact_04"]
  a_message.publish
  s.remark "== Published StkLaunchMissile Message =="
  s.remark "#{a_message}"
end

=end











=begin
s.step = 60.0

s.at(:next) do
  EndEngagement.new.publish
  s.remark "== Published EndEngagement Message =="
end


s.at(s.now + rand(5)) do
  EndRun.new.publish
  s.remark "== Published EndRun Message =="
end

=end


s.list  if $debug_sim


## The End
##################################################################

