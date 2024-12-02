#############################################################################
###
##  Name:   <%= scenario_name %>.rb
##  Desc:   <%= scenario_desc %>
##
##  This file is an example of an IseScenario file used by the
##  scenario_driver IseRubyModel.  =begin/end blocks comment out
##  examples of how to handle the publication of messages.
##
##  IseScenarios are used to react to specific circumstances wither
##  those circumstances are time-based or event-based.
##
##  See the ISE wiki topic IseScenario for additional information
#

#######################################################
## Require any project or system-wide libraries
## that may be needed by this IseScenario

require 'pp'    # ruby-object pretty printer



#######################################################
## require all the IseMessages used by this IseScenario

require 'AnyIseMessage' # An example


############################################################
## instantiate a new scenario with a single line description

s = IseScenario.new "<%= scenario_desc %>"

s.step = 1.0    ## time step in decimal seconds


############################################################
## This section illustrates time-based actions


# at(specific second into the simulation)
# 0.0 is a good place to initialize stuff
#     It is also the place to subscribe to IseMessages
s.at(0.0) do
  s.remark "Let the initialization begin"
  # Subscribe to messages at initialization time
  IseScenario.subscribe(AnyIseMessage)  # AnyIseMessage must be previously 'required'
                                        # Do not use a colon in front of the message name
end


# remark adds text to the log file
s.at(1.0)   { s.remark "Happens at One second" }

# Multiple blocks can be defined
s.at(1.0)   { s.remark "Also Happens at One second" }

# the :next time is always the last time + the step number of seconds
s.at(:next) { s.remark "two seconds" }
s.at(:next) { s.remark "three seconds" }

# specifically reset the time
s.at(0.5)   { s.remark "sequence does not have to be in order" }
# the last time is now 0.5
s.at(:next) { s.remark "1.5 seconds" }

# step size can be adjusted
s.step = 5.0

# The last time was 1.5 seconds; the step time is now 5.0 seconds so ....
# that makes the next time 6.5 seconds.
s.at(:next) do
  a_message = AnyIseMessage.new
  a_message.item_one_   = 1.0
  a_message.item_one_   = 2.0
  a_message.publish
  s.remark "== Published AnyIseMessage Message at 6.5 =="
end

# step size can be adjusted whenever it is necessary
s.step = 1.0

s.at(:next) do
  s.remark "== s.now is 7.5 =="
end


# now is the same as last
# You can use formulas as an argument, for example at a random offset to now.
# rand(5) returns an integer between 0 and 4 inclusive using a normal distribution.
s.at(s.now + rand(5)) do
  EndRun.new.publish
  s.remark "== Published EndRun Message =="
end

################################
# You can also do periodic tasks
s.every(10.0) do
  s.remark "Happens Every 10.0 Seconds - #{Time.now}"
end


############################################################
## This section illustrates event-based actions


# you can declare local variables outside of IseScenario blocks:
message_cnt = 0

# A received IseMessage generates an event
#    V<=- note the use of the colon
s.on(:AnyIseMessage) do
  # This block is executed whenever AnyIseMessage arrives
  a_header  = s.message(:AnyIseMessage)[0]  # The message's header
  a_message = s.message(:AnyIseMessage)[1]  # The message's content
  # do stuff with the message
  message_cnt += 1
  # events can be anything, not just receipt of IseMessages
  # declare an event with the set method
  s.set :received_three_messages if 3 == message_cnt
end

s.on(:received_three_messages) do
  s.remark "Received three messages"
  message_cnt = 0
end


## The End
##################################################################

