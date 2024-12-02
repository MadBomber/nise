##########################################################
###
##  File: process_command_line.rb
##  Desc: Process the command line
##
##  An Example Command Line:
##    peerrb -j10 -kruby_example_model -lruby_example_model.rb -u1 -c8001 -O -d -# --parm1
#


################################
## global options

=begin
# TODO: change $OPTIONS to have key :routers with value as a Hash with a key for the IseRouter
#       name and value is a Hash of options for that IseRouter.
#       We want something that looks like this:

$OPTIONS[:routers] = {
  :dispatcher => {
    :host => "localhost",
    :port => 8001
  }
  :amqp => {
    :host => "localhost",
    # ....etc.
  }
}

# Might want this junk to come from a YAML file like database.yml e.g. routers.yml

=end


$OPTIONS = {
  :web_service          => nil,   ## Supports Sinatra apps default service is thin
  :web_service_options  => {},
################################################
## From the command line
  :amqp             => false, ## --amqp         # TODO: setup a :routers key
  :dispatcher       => false, ## --dispatcher   # TODO: setup a :routers key
  :run_id           => nil,   ## -j
  :model_name       => nil,   ## -k
  :library          => nil,   ## -l (same as :model_name +".rb"
  :unit_number      => nil,   ## -u
  :connection_port  => nil,   ## -c (port used to connect with IseDispatcher)
  :redirect_stdout  => true,  ## -O (puts stdout into #{model_name}#{unit_number}.txt )
  :debug            => false, ## -d (sets $debug)
  :verbose          => false, ## -v (sets $verbose)
  :model_parms      => [],    ## -# parameters for the model follow
  :control_port     => nil,   ## -p control_port for human in the loop interactions
#################################################
## from system environment variables
  :dispatcher_ip    => '127.0.0.1'
}


$usage_options = nil

ARGV.options do |o|

  $usage_options = o

  o.set_summary_indent('  ')
  o.define_head "The Ruby IsePeer"
  o.separator   ""
  o.separator   "Mandatory arguments to long options are mandatory for short options too."

  o.on( "--amqp", "Support AMQP-based Messages")                                    { |v| $OPTIONS[:amqp] = v }
  o.on( "--dispatcher", "Support IseDispatcher-based Messages")                     { |v| $OPTIONS[:dispatcher] = v }
  
  o.on("-j", "--run_id=val", Integer, "ID of the run this model is to be attached") { |v| $OPTIONS[:run_id] = v }
  o.on("-k", "--model_name=val", String, "Name of this model in the IseDatabase")   { |v| $OPTIONS[:model_name] = v }
  o.on("-d", "--debug", "Turn Debug On")                                            { |v| $OPTIONS[:debug] = v }
  o.on("-v", "--verbose", "Turn Verbose On")                                        { |v| $OPTIONS[:verbose] = v }

  o.on("-l", "--library=val", String, "Library File Name including the '.rb' extension")      { |v| $OPTIONS[:library] = v }
  o.on("-u", "--unit=val", Integer, "The unit number within the IseJob for this model")       { |v| $OPTIONS[:unit_number] = v }
  o.on("-c", "--connection_port=val", Integer, "Port number for connecting to the IseDispatcher") { |v| $OPTIONS[:connection_port] = v }
  o.on("-p", "--control_port=val", Integer, "Port number for man-in-the-loop control") { |v| $OPTIONS[:control_port] = v }

  o.on("-O", "--redirect_stdout", "Redirects stdout to a file.")                            { |v| $OPTIONS[:redirect_stdout] = v }

  o.on("-#",  "Parameters for Model Follow")                            { $OPTIONS[:model_parms] = ARGV; o.terminate }

  o.separator ""
  o.on_tail("-h", "--help", "Show this help message.") { $stderr.puts o; exit }

#  begin
    o.parse!
#  rescue OptionParser::ParseError => e
#    $stderr.puts "ERROR: #{e}"
#    $stderr.puts o
#    exit(-1)
#  end

end

command_line_errors = false

required_parms = [  :run_id,
                    :model_name,
                    :library,
                    :unit_number]       #,
#                    :connection_port]  # only required with the dispatcher


required_parms.each do |parm|
  unless $OPTIONS[parm]
    $stderr.puts "ERROR: missing the #{parm} parameter"
    command_line_errors = true
  end
end


unless $OPTIONS[:amqp]  ||  $OPTIONS[:dispatcher]
  $stderr.puts "ERROR: Must specify an IseRouter (--amqp or --dispatcher)"
  command_line_errors = true
end


############################################################
## Validate agains the IseDatabase

$run_record = Run.find($OPTIONS[:run_id])

unless $run_record
  $stderr.puts "ERROR: The run_id #{$OPTIONS[:run_id]} is invalid."
  command_line_errors = true
end

$model_record = Model.find_by_name($OPTIONS[:model_name])

unless $model_record
  $stderr.puts "ERROR: The run_id #{$OPTIONS[:model_name]} is invalid."
  command_line_errors = true
end



if command_line_errors
  $stderr.puts $usage_options 
  exit(-1)
end

$OPTIONS[:dispatcher_ip] = $ISE_GATEWAY if $ISE_GATEWAY


$debug   = $OPTIONS[:debug]
$verbose = $OPTIONS[:verbose]


############################################################
## Redirect standard output to a unique file for this IseRun

if $OPTIONS[:redirect_stdout]
  stdout_filename = Pathname.new($run_record.output_dir) + 
                    "#{$OPTIONS[:model_name]}#{$OPTIONS[:unit_number]}.txt"

  stdout_filename_str = stdout_filename.to_s

  $stderr.puts "DEBUG: stdout_filename -=> #{stdout_filename}" if $debug
  $orig_stdout = $stdout
  $stdout = File.new(stdout_filename_str, 'w')
end


#  $orig_stdout = $stdout
#  $stdout = File.new('stdout.txt', 'w')


if $debug or $verbose or $DEBUG
  puts "From: #{File.basename(__FILE__)} at line #{__LINE__}"
  pp $OPTIONS
  puts '-'*20
  pp $run_record
  puts '-'*20
  pp $model_record
  puts '='*60
end



