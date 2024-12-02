#!/usr/bin/env ruby
###############################################################
###
##  File: amqp_sim_control.rb
##  Desc: Inserts SimControl messages into an AMQP exchange
##
##  Use --help to see usage documentation
#

require 'rubygems'    # required by Ruby v1.8.7
require 'bunny'       # GEM: wrapper around the AMQP gem
require 'json'        # GEM
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
$options[:vhost]     = ENV['AMQP_VHOST']    || '/'
$options[:logfile]   = ENV['AMQP_LOGFILE']  || ''   # empty string means do not log the amqp traffic

$options[:debug]     = false
$options[:verbose]   = false
$options[:json]      = true     # send command as json
$options[:text]      = false    # send command as text
$options[:both]      = false    # send command as text and json

$options[:consumer]  = "amqp_control-#{$$}"

$options[:run_id]    = 0        # Used if all the user knows is the run ID


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
    -t --type         topic         AMQP_TYPE
    -u --username     guest         AMQP_USER
    -p --password     guest         AMQP_PASS
    -l --logfile      ''            AMQP_LOGFILE      This is the AMQP protocol traffic logfile

The default column shows the value that will be used when there
is no value for the environment variable and no command line over-ride
has been specified.

EOS


#######################################################################
## Command line parameters over-ride environment variables and defaults

save_ARGV = ARGV.dup

unless ARGV.empty?

  script_name = File.basename($0)
  
  ARGV.options do |o|

    o.set_summary_indent('  ')
    o.banner =    "Usage: #{script_name} [options] ControlMessage"
    o.define_head "AMQP Sim Control - Inserts a plain text message into an exchange"
    
    o.separator   ""
    o.separator   "ControlMessage is required."
    o.separator   ""
    
    o.separator   "Values used when no command line parameter is present are"
    o.separator   "shown in (parenthesis)"
    o.separator   ""
        
    o.on("-H", "--host=val", String,      "Host Computer #{df :host}")          { |v| $options[:host] = v }
    o.on("-V", "--vhost=val", String,     "Virtural Host #{df :vhost}")         { |v| $options[:vhost] = v }
    o.on("-e", "--exchange=val", String,  "Exchange Name #{df :exchange}")      { |v| $options[:exchange] = v }
    
    o.on("-r", "--run=val", Integer,      "Run ID #{df :run_id}")               { |v| $options[:run_id] = v.to_i }
    
    o.on("-t", "--type=val", String,      "Type of Exchange #{df :type}")       { |v| $options[:type] = v }
    o.on("-u", "--username=val", String,  "User's Account Name #{df :user}")    { |v| $options[:user] = v }
    o.on("-p", "--password=val", String,  "Account Password #{df :pass}")       { |v| $options[:pass] = v }
    o.on("-l", "--logfile=val", String,   "AMQP Protocol Log #{df :logfile}")   { |v| $options[:logfile] = v }

    o.separator ""

    o.on( "--json", "Send Command as JSON #{df :json}")                 { |v| $options[:json] = true; $options[:text] = false}
    o.on( "--text", "Send Command as Text #{df :text}")                 { |v| $options[:text] = true; $options[:json] = false}
    o.on( "--both", "Send Command as Both Text and JSON #{df :both}")   { |v| $options[:text] = true; $options[:json] = true }
    
    o.separator ""

    o.on("-d", "--debug", "Turn Debug On #{df :debug}")       { |v| $options[:debug] = true }
    o.on("-v", "--verbose", "Print Actions #{df :verbose}")   { |v| $options[:verbose] = true }

    o.separator ""
    
    o.on_tail("-h", "--help", "Show this help message.") { puts; puts o; puts additional_help; exit }
    
    o.parse!
  
  end ## end of ARGV.options do |o|

end ## end of unless ARGV.empty?


$debug    = $options[:debug]
$verbose  = $options[:verbose]


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




if ARGV.empty?

  puts ""
  puts "No ControlMessage was specified"
  puts "Use --help to see usage instructions"
  puts ""
  exit(1)

end

sim_control_message_text = ARGV.join(' ')
sim_control_message_json = {'command' => sim_control_message_text}.to_json



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



if $debug or $verbose

  print "\n\n"
  puts "="*40
  pp session

  print "\n\n"
  puts "="*40
  pp exchange
  
end ## end of if $debug or $verbose


# publish into the exchange the sim_control_message

if $options[:json]
  exchange.publish(sim_control_message_json, :content_type => 'application/json', :key => 'SimControl.0.0')
  puts "published this -=> #{sim_control_message_json}" if $debug or $verbose
end

if $options[:text]
  exchange.publish(sim_control_message_text, :content_type => 'text/plain', :key => 'SimControl.0.0')
  puts "published this -=> #{sim_control_message_text}" if $debug or $verbose
end


##################################################################
## Terminate current session and exit

begin
  session.stop 
rescue Exception => e
  puts "AMQP session#stop FAILED: #{e}"
end



