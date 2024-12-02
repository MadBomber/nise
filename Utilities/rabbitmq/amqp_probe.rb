#!/usr/bin/env ruby
###############################################################
###
##  File: amqp_probe.rb
##  Desc: logs all AMQP/JSON messages from an exchange
##
##  Use --help to see usage documentation
##
## NOTE: the --raw options is only for JSON payloads
#

module SCM
  ID        = "$Id: amqp_probe.rb 1833 2011-08-04 22:36:35Z dvanhoozer $"
  REVISION  = "$Revision: 1833 $"
end

require 'rubygems'    # required by Ruby v1.8.7
require 'bunny'       # GEM: wrapper around the AMQP gem
#require 'json'        # GEM
require 'optparse'    # Ruby standard library
require 'pp'          # Ruby standard library

# Trap control-c interruption
user_interrupted = false
trap("INT") { user_interrupted = true; exit }

# Set default options
$options = Hash.new

$options[:host]      = ENV['AMQP_HOST']     || 'localhost'
$options[:user]      = ENV['AMQP_USER']     || 'guest'
$options[:pass]      = ENV['AMQP_PASS']     || 'guest'
$options[:type]      = ENV['AMQP_TYPE']     || 'topic'
$options[:exchange]  = ENV['AMQP_EXCHANGE'] || 'TestExchange'

$options[:run_id]    = 0        # Used if all the user knows is the run ID

$options[:queue]     = ENV['AMQP_QUEUE']    || "AmqpProbe-#{$$}"

$options[:auto_delete]  = true  # controls existance of queue when there are no consumers attached

$options[:key]       = ENV['AMQP_KEY']      || '#'  # The single character '#' matches everything
$options[:vhost]     = ENV['AMQP_VHOST']    || '/'
$options[:logfile]   = ENV['AMQP_LOGFILE']  || ''   # empty string means do not log the amqp traffic
$options[:timeout]   = ENV['AMQP_TIMEOUT']  || 10.0 # 0.0 seconds means do not timeout

$options[:debug]     = false
$options[:verbose]   = false
$options[:raw]       = false

$options[:delete]    = false

$options[:consumer]  = "amqp_probe-#{$$}"


###############################################################
## helpers for help output

def df(a_sym)
  "(#{$options[a_sym]})"
end

additional_help = <<-EOS

The command line parameters are used to over-ride the values
obtained from system environment variables.  The following
system environment variables are associated with the indicated
command line parameter:

Cmd Line Parameter    Default       System Environment Variable
    -H --host         localhost     AMQP_HOST
    -V --vhost        /             AMQP_VHOST
    -e --exchange     TestExchange  AMQP_EXCHANGE
    -r --run          0                               Get the GUID for this run as the exchange
       --raw          false                           Log raw json with timestamps for later playback
    -q --queue        everything    AMQP_QUEUE
    -t --type         topic         AMQP_TYPE
    -k --key          #             AMQP_KEY          The routine_key to use
    -u --username     guest         AMQP_USER
    -p --password     guest         AMQP_PASS
    -l --logfile      ''            AMQP_LOGFILE      This is the AMQP protocol traffic logfile
    -T --timeout      10.0 seconds  AMQP_TIMEOUT      0.0 means no timeout

The default column shows the value that will be used when there
is no value for the environment variable and no command line over-ride
has been specified.

#{SCM::ID}
#{SCM::REVISION}

EOS


#######################################################################
## Command line parameters over-ride environment variables and defaults

save_ARGV = ARGV.dup

unless ARGV.empty?

  script_name = File.basename($0)
  
  ARGV.options do |o|

    o.set_summary_indent('  ')
    o.banner =    "Usage: #{script_name} [options]"
    o.define_head "AMQP Queue Probe - emptys a queue to standard out assuming JSON payloads"
    
    o.separator   ""
    o.separator   "Values used when no command line parameter is present are"
    o.separator   "shown in (parenthesis)"
    o.separator   ""
        
    o.on("-H", "--host=val", String,      "Host Computer #{df :host}")          { |v| $options[:host] = v }
    o.on("-V", "--vhost=val", String,     "Virtural Host #{df :vhost}")         { |v| $options[:vhost] = v }
    o.on("-e", "--exchange=val", String,  "Exchange Name #{df :exchange}")      { |v| $options[:exchange] = v }
    o.on("-q", "--queue=val", String,     "Queue Name #{df :queue}")            { |v| $options[:queue] = v }
    o.on("-k", "--key=val,val", String,   "Comma seperated List ofRouting Keys #{df :key}")             { |v| $options[:key] = v }
    o.on("-t", "--type=val", String,      "Type of Queue #{df :type}")          { |v| $options[:type] = v }
    o.on("-u", "--username=val", String,  "User's Account Name #{df :user}")    { |v| $options[:user] = v }
    o.on("-p", "--password=val", String,  "Account Password #{df :pass}")       { |v| $options[:pass] = v }
    o.on("-l", "--logfile=val", String,   "AMQP Protocol Log #{df :logfile}")   { |v| $options[:logfile] = v }
    o.on("-T", "--timeout=val", Float,  "Quit after X seconds of no traffic #{df :timeout}")  { |v| $options[:timeout] = v }

    o.separator ""
    o.on("-r", "--run=val", Integer,      "Run ID #{df :run_id}")               { |v| $options[:run_id] = v.to_i }
    o.separator ""

    o.on("-D", "--delete", "Delete the Queue on exit #{df :delete}") { |v| $options[:delete] = v }

    o.separator ""

    o.on("-d", "--debug", "Turn Debug On #{df :debug}")       { |v| $options[:debug] = true }
    o.on("-v", "--verbose", "Print Actions #{df :verbose}")   { |v| $options[:verbose] = true }
    o.on("",   "--raw", "Record in raw format #{df :raw}")    { |v| $options[:raw] = true }
    
    o.separator ""
    
    o.on_tail("-h", "--help", "Show this help message.") { puts; puts o; puts additional_help; exit }
    
    o.parse!
  
  end ## end of ARGV.options do |o|

end ## end of unless ARGV.empty?


$debug    = $options[:debug]
$verbose  = $options[:verbose]
$raw      = $options[:raw]

if $debug or $verbose
  puts "ARGV:"
  pp save_ARGV
  puts "Options:"
  pp $options
end



unless 0 == $options[:run_id]

  require 'IseRun'

  begin
    run_record = Run.find $options[:run_id]
  rescue ActiveRecord::RecordNotFound
    run_record = nil
  end
  
  if run_record.nil?
    puts "ERROR: Invalid run ID was specified: #{$options[:run_id]}"
    puts "       The ISE_QUEEN: #{$ISE_QUEEN}"
    exit(-1)
  end
  
  unless $options[:exchange].empty?
    puts "WARNING: AMQP Exchange #{$options[:exchange]} is being over-riden with #{run_record.guid}"
  end

  $options[:exchange] = run_record.guid

end




# Establish an AMQP session
session = Bunny.new(  :user     => $options[:user], 
                      :pass     => $options[:pass], 
                      :host     => $options[:host], 
                      :logging  => ($options[:logfile].length > 0),
                      :logfile  => $options[:logfile],
                      :vhost    => $options[:vhost],
                      :spec     => '09')

begin
  session.start
rescue Bunny::ProtocolError
  puts "AMQP host #{amqp_host} does not support the 09 AMPQ orotocol specification; OR"
  puts "the user name (#{$options[:user]}) and password are not known.  Both conditions produce the same exception."
  exit(1)
rescue Exception => e
  puts "Unable to connect to an AMQP server@#{$options[:host]} because: #{e}"
  msg = "Unable to connect to the AMQP server@#{$options[:host]} as #{$options[:user]}; suspect the server is not running."
  $stderr.puts msg
  exit(2)
end

# link_to or create an exchange of the specified type (usually topic for ISE project)
exchange = session.exchange($options[:exchange], :type => $options[:type].to_sym)

# link_to or create a message queue

begin
  msg_queue = session.queue($options[:queue], :auto_delete => $options[:auto_delete] )
rescue Bunny::ForcedChannelCloseError => e
  if e.to_s.include? "Error Reply Code: 406"
    # 406 means the existing queue does not have the same parameters as was passed
    # IMHO every queue should be auto_delete but the JAVA-junk is not setup with that
    # as a default.
    msg_queue = session.queue($options[:queue] )
  else
    puts "ERROR: #{e}"
    exit(-1)
  end
end


# bind routing key(s) to the queue
unless $options[:key].empty?
  my_keys = $options[:key].split(',')
  my_keys.each do |routing_key|
    msg_queue.bind(exchange, :key => routing_key )
    puts "#{$options[:queue]} bound to '#{routing_key}'" if $verbose or $debug
  end
end


if $debug or $verbose

  print "\n\n"
  puts "="*40
  pp session

  print "\n\n"
  puts "="*40
  pp exchange

  print "\n\n"
  puts "="*40
  pp msg_queue

end ## end of if $debug or $verbose

##################################################################
at_exit do

  if $debug or $verbose
    puts
    puts "Terminated at the request of the user." if user_interrupted
  end

  if $options[:delete]
    begin
      msg_queue.delete
      puts "The '#{$options[:queue]}' queue has been deleted." if $debug or $verbose
    rescue Exception => e
      puts "AMQP msg_queue#delete FAILED: #{e}"
    end
  end

  begin
    session.stop 
  rescue Exception => e
    puts "AMQP session#stop FAILED: #{e}"
  end

end ## at_exit do



##################################################################
## Begin Message Loop

base_time           = Time.now
relative_time_last  = 0.0


msg_queue.subscribe(  :consumer_tag => $options[:consumer],
                      :header       => true,
                      :timeout      => $options[:timeout].to_f
) do |received_message|
  
  if $raw
    relative_time       = (Time.now - base_time).to_f
    wait_time           = relative_time - relative_time_last
    relative_time_last  = relative_time
    routing_key         = received_message[:delivery_details][:routing_key]
  else
    puts
    puts "-"*40
    puts "Header: #{received_message[:header].inspect}"

    puts "Delivery Details:"
    pp received_message[:delivery_details]

    puts "Message Payload:"
  end
  
  

  
  if $raw

    puts "raw\t#{wait_time}\t#{routing_key}\t#{received_message[:payload]}"

  else
  
    case received_message[:header].content_type
      when 'application/json' then
        unless $raw
          pp  received_message[:payload] # JSON.parse received_message[:payload]
        else
          puts "raw\t#{relative_time.to_f}\t#{routing_key}\t#{received_message[:payload]}"
        end
      when 'text/plain' then
        puts received_message[:payload]
      else
        pp received_message[:payload]
    end
  
  end

  $stdout.flush   ## default ruby buffer size is 32k; default only flushes when buffer full

end 


if $debug or $verbose
  puts
  puts "Wueue subscription timed out after #{$options[:timeout]} seconds."
end

