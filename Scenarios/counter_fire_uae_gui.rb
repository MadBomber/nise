#############################################################################
###
##  Name:   counter_fire_uae_gui.rb
##
##  Desc:   An example scenario to illustrate the use of a event driven scenario.
##          The implacement locations are in the UAE and Iran
##
##          This senario is designed to run concurrently with the
##          counter_fire_uae.rb scenario.  These two scenario are
##          run by different instances of the ScenarioDriver.  In this
##          way the event driven scenario can use a GUI that waits
##          on man-in-the-loop decisions before invoking some action.
##

s = IseScenario.new "GUI for Missile Counter-fire UAE"

require 'systemu'
require 'SimTime'

$sim_time = SimTime.new(  0.1,
                          '27 Jul 1953 11:00:00.000',
                          '27 Jul 1953 11:30:00.000' )


######################################################
## Define the laydown junk as global hashes

blue_launchers  = []

blue_launchers << { :name => "CounterFire_01", :position => [25.74118551199947, 55.95157251495233, 0.0] }
blue_launchers << { :name => "CounterFire_02", :position => [25.11366215110153, 56.31439207624835, 0.0] }




##################################################
## require all the messages to be sent or received

require 'StkLaunchMissile'    ## equivalent to a FireOrder
require 'RequestForFire'

require 'EndEngagement'
require 'EndRun'



############################################################
## instantiate a new scenario with a single line description

s.at(0.0) do
  IseScenario.subscribe(RequestForFire)
end




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

