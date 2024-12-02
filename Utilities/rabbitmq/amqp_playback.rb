#!/usr/bin/env ruby
###############################################################
###
##  File: amqp_playback.rb
##  Desc: Inserts messages into an AMQP exchange from a
##        raw file captured from the amqp_probe.rb utility
##
##  Use --help to see usage documentation
#

module SCM
  ID        = "$Id: amqp_playback.rb 1833 2011-08-04 22:36:35Z dvanhoozer $"
  REVISION  = "$Revision: 1833 $"
end

require 'rubygems'    # required by Ruby v1.8.7
require 'pathname'    # STDLIB: cross platform file/directory stuff
require 'bunny'       # GEM: wrapper around the AMQP gem
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
$options[:logfile]   = ENV['AMQP_LOGFILE']  || 'raw.txt'

$options[:debug]     = false
$options[:verbose]   = false
$options[:json]      = true     # send command as json
$options[:text]      = false    # send command as text
$options[:both]      = false    # send command as text and json

$options[:consumer]  = "amqp_playback-#{$$}"

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
    -l --logfile      'raw.txt'     AMQP_LOGFILE      This is the file containing the AMQP messages to playback
    
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
    o.banner =    "Usage: #{script_name} [options] -l raw_message_file"
    o.define_head "AMQP Playback - Inserts messages from a capture file into an exchange"
    
    o.separator   ""
    o.separator   "'-l raw.txt' is required. (use your own file name)"
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

#    o.on( "--json", "Send Command as JSON #{df :json}")                 { |v| $options[:json] = true; $options[:text] = false}
#    o.on( "--text", "Send Command as Text #{df :text}")                 { |v| $options[:text] = true; $options[:json] = false}
#    o.on( "--both", "Send Command as Both Text and JSON #{df :both}")   { |v| $options[:text] = true; $options[:json] = true }
    
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






if $options[:logfile].length > 0
  logfile = Pathname.new $options[:logfile]
  unless logfile.exist?
    puts
    puts "ERROR: The designated logfile does not exist.  Use the -l command to"
    puts "       designate the previously recoded logfile."
    puts "       Bad file: #{logfile.realpath}"
    puts
    exit(-1)
  end
else
  puts
  puts "ERROR: No logfile was specified.  Use the -l command to"
  puts "       designate the previously recoded logfile."
  puts
  exit(-1)
end





###############################################################
# Establish an AMQP session
session = Bunny.new(  :user     => $options[:user], 
                      :pass     => $options[:pass], 
                      :host     => $options[:host], 
                      :logging  => false,
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



loop_counter = 0  # counts the number of times the logfile has been processed

at_exit do ## Terminate current session and exit
  begin
    session.stop
    puts loop_counter
  rescue Exception => e
    puts "AMQP session#stop FAILED: #{e}"
  end
end




##################################################################
## replay the message buffer

while true    # loop forever; control-c will terminate the process

  puts "="*45 if $verbose
  loop_counter += 1
  

  logfile.each_line do | current_line |
  
    current_fields = current_line.split("\t")
    
    if 'raw' == current_fields[0]
      t = current_fields[1][0,5].to_f
      puts t if $debug
      sleep(t)
      print '.' if $verbose
      exchange.publish( current_fields[3],
                        :content_type => 'application/json',
                       :key => current_fields[2]
                      )
      
    end
    
  end
  
  logfile.open  # reopen file

end



