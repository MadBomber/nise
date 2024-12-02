#!/usr/bin/env ruby
########################################################################
###
##  File:  subscribed.rb
##  Desc:  Lists the messages to which a running model has subscribed
#

require 'IseDatabase'

def subscribed (model_name)
  model_rec  = Model.find_by_name(model_name)
  puts "#{model_rec.name} -- #{model_rec.description}"
  puts
  puts "... has subscribed to the following messages:"
  puts
  run_peer_rec = RunPeer.find_last_by_peer_key(model_name)
  run_subscriber_rec = RunSubscriber.find_all_by_run_peer_id(run_peer_rec.id)
  run_subscriber_rec.each do |run_subscriber|
    run_message_rec = RunMessage.find_by_id(run_subscriber.run_message_id)
    app_message_rec = AppMessage.find(run_message_rec.app_message_id)
    puts "  #{app_message_rec.app_message_key} -- #{app_message_rec.description}"
  end
end

ARGV.each do |m_name|
  puts
  subscribed m_name
  puts
end
