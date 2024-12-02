#!/usr/bin/env ruby
###########################################################################
###
##  File: delete_old_amqp_queues.rb
##  Desc: Name says it all.  Host defaults to 127.0.0.1 if
##        there is no system environment variable AMQP_HOST which is
##        used if there is no command line parameter.
##
##  Usage:
##          delete_old_amqp_queues.rb [amqp_host]
#

unless ENV['ISE_ROOT']
  puts
  puts "ERROR: The ISE_ROOT system environment variable is not set."
  puts
  exit(-1)
end

messages_trigger    = 100
idle_since_trigger  = 15.0 * 60.0 # units: seconds


require 'rubygems'  # required for Ruby versions prior to 1.9
require 'pathname'  # cross platform file paths
require 'pp'

ISE_ROOT        = Pathname.new ENV['ISE_ROOT']

unless ISE_ROOT.exist? and ISE_ROOT.directory?
  puts
  puts "ERROR: The ISE_ROOT system environment variable is not a valide directory."
  puts
  exit(-1)
end

require 'active_support'  # Has the DateTime#to_f method
require 'systemu'         # Used to retrieve stdout from the command line
require 'ap'              # pretty prints an array
require 'ise_logger'      # standard ISE logger


ISE::Log.new
ISE::Log.progname="delete_old_amqp_queues"


RABBITMQ_ADMIN  = ISE_ROOT + 'Utilities' + 'rabbitmq' + 'rabbitmq_admin.py'

AMQP_HOST       = ARGV[0]
AMQP_HOST     ||= ENV['AMQP_HOST'] || '127.0.0.1'

ISE::Log.debug( ENV['USER'] + ": Reviewing queues on AMQP host: #{AMQP_HOST}" )


list_queues_params = "list queues -H #{AMQP_HOST}" # -f tsv"

a,b,c = systemu("#{RABBITMQ_ADMIN} #{list_queues_params}")

q_array = []
q_array << b.split("\n").map {|q| q.split("|").map {|e| e.strip} }

if 'No items' == q_array[0][0][0]
  my_msg = "There are no queues on AMQP Host: #{AMQP_HOST}"
  ISE::Log.info my_msg
  puts
  exit(0)
end


the_q_array   = q_array[0].dup
last_element  = the_q_array.length - 1


element_names = ["",
  "vhost",
  "name",
  "auto_delete",
  "consumers",
  "durable",
  "exclusive_consumer_pid",
  "exclusive_consumer_tag",
  "idle_since",
  "memory",
  "messages",
  "messages_ready",
  "messages_unacknowledged",
  "node",
  "owner_pid",
  "pid"]


unless the_q_array[1] == element_names

  missing_fields = element_names - the_q_array[1]
  
  if 1 == missing_fields.length and 'idle_since' == missing_fields[0]
    # All queues are active
    exit(0)
  end
  
  puts
  puts "ERROR: The returned list of queues is not in the expected format"
  puts
  puts "Expected this format order:"
  ap element_names
  puts
  puts "Received this format order:"
  ap the_q_array[1]
  puts
  puts "Missing Fields:"
  ap missing_fields
  exit(-1)
end

the_q_array[0]            = nil
the_q_array[1]            = nil
the_q_array[2]            = nil
the_q_array[last_element] = nil

# get rid of the junk leaving only the queue information
the_q_array.compact!


name_index        = element_names.index("name")
idle_since_index  = element_names.index("idle_since")
messages_index    = element_names.index(  "messages")

#debug_me { [ :the_q_array, :name_index, :idle_since_index, :messages_index ] }


the_q_array.each do |q|

  messages    = q[messages_index].to_i
  queue_name  = q[name_index]

  begin
    idle_since  = DateTime.parse(q[idle_since_index])
  rescue ArgumentError
    puts "ArgumentError: idle_since: '#{q[idle_since_index]}'  undelivered messages: #{messages}  queue: #{queue_name}"
    idle_since  = DateTime.now
  end
  
  seconds_ago = DateTime.now.to_f - idle_since.to_f
  
  if messages >= messages_trigger or seconds_ago >= idle_since_trigger
    system "amqp-deleteq -H #{AMQP_HOST} #{queue_name}"    
    my_msg = "Deleted queue #{queue_name} on Host #{AMQP_HOST}"
    ISE::Log.info(my_msg)
  end

end




