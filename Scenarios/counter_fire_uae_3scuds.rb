#############################################################################
###
##  Name:   counter_fire_uae_3scuds.rb
##
##  Desc:   An example scenario to illustrate the use of a timed scenario.
##          The implacement locations are in the UAE and Iran
##
##          This scenario can be used in combination with the
##          counter_fire_uae_gui.rb file running within a different
##          instance of the ScenarioDriver.
##

puts "Entering: #{File.basename(__FILE__)}" if $debug

=begin
$debug       = false
$debug_sim   = false
$debug_stk   = false
=end

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



$blue_radars["SearchRadar_01"]   = [25.26052055530917, 55.3508101690813, 0.0]
$blue_radars["SearchRadar_02"]   = [24.25413070088112, 54.55057856802998, 0.0]
$blue_radars["SearchRadar_03"]   = [24.33110253275136, 52.59954957745941, 0.0]

$blue_radars["TrackingRadar_01"]   = [25.27965317137238, 55.36665872621656, 0.0]
$blue_radars["TrackingRadar_02"]   = [24.52813389622072, 55.01237880477231, 0.0]
$blue_radars["TrackingRadar_03"]   = [24.26349789815201, 54.52815633385707, 0.0]

pp $blue_radars
puts "-"*25

$blue_launchers["InterceptorSite_01"]   = [25.27096973125826, 55.35747268360237, 0.0]
$blue_launchers["InterceptorSite_02"]   = [24.52529892758981, 54.96897145551593, 0.0]
$blue_launchers["InterceptorSite_03"]   = [24.25849481827881, 54.51691686115401, 0.0]
$blue_launchers["CounterFire_01"]       = [25.74118551199947, 55.95157251495233, 0.0]
$blue_launchers["CounterFire_02"]       = [25.11366215110153, 56.31439207624835, 0.0]


pp $blue_launchers
puts "-"*25

#######################
## Red Force Laydown ##
#######################

######################
# Missile Launch Sites




$red_launchers["BallisticLaunchSite_01"]   = [27.1533554631633,  56.19416170183767, 0.0]
$red_launchers["BallisticLaunchSite_02"]   = [25.65490181808794, 57.78562077128066, 0.0]
$red_launchers["BallisticLaunchSite_03"]   = [26.52613306221384, 53.97664294467753, 0.0]



pp $red_launchers
puts "-"*25


#################
# Missile Impacts



$red_rocket_impacts["TargetSite_01"]   = [24.46475747875493, 54.3641579250639, 0.0]
#$red_rocket_impacts["TargetSite_02"]   = [25.25056454020101, 55.2897492333, 0.0]


pp $red_rocket_impacts
puts "-"*25

scud_counter = 0

$red_rocket_tracks  = Hash.new

$red_launchers.each do |rrl|

  $red_rocket_impacts.each do |rri|
    scud_counter += 1
    $red_rocket_tracks["scud_#{scud_counter}"] = [rrl, rri]
  end

end



puts "Red Rocket Tracks:"
pp $red_rocket_tracks
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

s = IseScenario.new "Missile Counter-fire UAE"
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
    a_message.target_position_  = $red_rocket_tracks[track_label][0][1]
    a_message.publish
    s.remark "==== Published RequestForFire track_label: #{track_label}"
  end
  
end



my_tracks=[]
s.on(:StkMissileDetected) do
  
  unless my_tracks.include? s.message(:StkMissileDetected)[1].label_
  
    s.remark "===Tasking Tracking Radar to acquire: #{s.message(:StkMissileDetected)[1].label_}"
  
    my_tracks << s.message(:StkMissileDetected)[1].label_
    a_message = StkTrackMissile.new
    a_message.label_     = s.message(:StkMissileDetected)[1].label_
    a_message.position_  = s.message(:StkMissileDetected)[1].position_
    a_message.range_     = s.message(:StkMissileDetected)[1].range_
    a_message.publish
    
  end
  
end




#########################################################
## Time-based tasks

s.step = 2.0

$red_rocket_tracks.each_pair do |rrt_k, rrt_v|

  s.at(:next) do
    a_message = StkLaunchMissile.new
    a_message.label_            = rrt_k
    a_message.launch_position_  = rrt_v[0][1]   # [0][0] has the launch site label
    a_message.target_position_  = rrt_v[1][1]   # [1][0] has the impact site label
    a_message.publish
    s.remark "= Published StkLaunchMissile Message for rrt_k: #{rrt_k}"
  end

end



############################################################
## All Red Rockets have impacted by 4 minutes and 35 seconds

s.at(295.0) do
  er = EndRun.new
  er.publish
end



s.list  if $debug_sim


## The End
##################################################################

