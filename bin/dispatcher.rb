#!/usr/bin/env ruby
#############################################################
## dispatcher controls the IseDispatchers

require 'IseDrone'        ## The methods necessary to regrister an IseDrone in the IseDatabase
require 'IseDispatcher'   ## The control class for the ISE dispatcher
require 'optparse'        ## lib: used for the command line
require 'ostruct'         ## lib: OpenStruct class

return_value = 0      ## Used to communication with the enclosing shell on exit
is_good      = true   ## Assume all command line options parse correctly

#################
# default options

options = OpenStruct.new

options.anneal        = false   ## Tells all dispatchers to update their routing tables
options.list          = false   ## List the active dispatchers on the world-wide grid
options.clean         = false   ## Test each dispatcher on the world-wide grid, if not responding remove its record
options.debug         = false   ## Set debug mode, $DEBUG is global $debug is local
options.info          = false   ## Retrieve informat from a dispatcher
options.verbose       = false   ## Set berbose mode, $VERBOSE is global, $verbose is local
options.grid          = false   ## Operate on the local grid cluster, unless overridden by --remote
options.stop          = false   ## Stop a dispatcher
options.kill_scope    = false   ## Stop lots of dispatchers, either localhost, cluster or all
options.start         = false   ## Start dispatcher(s) uses --grid for starting local grid cluster or --remote hots
options.stats         = false   ## FIXME: How does this differ from info?
options.show_warnings = false   ## Print warning messages, otherwise no warnings
options.remote_hosts  = false   ## Array of remote hosts from the --remote option; requires --grid to work
options.output_format = :text   ## Specifies report formats: text (default), html, xml, yaml, twiki
options.kill_run      = false   ## kill a specific run
options.kill_model    = false   ## kill a specific model (future featurel need to figure out what "model" means
options.conf_file     = ""  ## the key of the connection tables to be read from the name_value table, defaults to "dispatcher.conf".

o = OptionParser.new do |o|

  script_name = File.basename($0)

  o.set_summary_indent('  ')
  o.banner =    "Usage: #{script_name} [options]"
  o.define_head "ISE dispatcher control script"
  o.separator   ""
  o.separator   "Mandatory arguments to long options are mandatory for short options too."

  o.on("-a", "--anneal",   "anneal the cluster's dispatchers")  { |v| options.anneal = v }
  o.on("-i", "--info",     "info this nodes dispatcher")        { |v| options.info   = v }
  o.on("-c", "--clean",    "clean up the database")             { |v| options.clean  = v }
  o.on("-d", "--debug",    "Set debug mode")                    { |v| options.debug  = v }
  o.on("-l", "--list",     "list all active dispatchers")       { |v| options.list   = v }
  o.on("-s", "--start",    "start this nodes dispatcher")       { |v| options.start  = v }
  o.on("-k", "--stop",     "kill this nodes dispatcher")        { |v| options.stop   = v }
  o.on("-f", "--file=val", "configuration file name")           { |v| options.conf_file = v }
  o.on("--killrun=val",    "kill a given run")                  { |v| options.kill_run = v }
#  o.on("--killmodel=val", "kill a given model")                    { |v| options.kill_model = v }

  o.on( "--kill SCOPE", [:localhost, :cluster, :all],
  "Kill (stop) dispatchers on the SCOPE:",
  "  localhost .. just your localhost (same as --stop)",
  "  cluster .... the local $ISE_CLUSTER",
  "  all ........ the entire ISE grid") do |scope|
    options.kill_scope = scope
  end

  o.on( "--output FORMAT", [:text, :html, :wiki, :xml, :yaml, :json],
  "Output format for selected reports:",
  "  text .. (default) for use on console",
  "  html .. for embedding within a web page",
  "  wiki .. for embedding within an ISEwiki page",
  "  xml ... for service response",
  "  json .. for service response",
  "  yaml .. for service response"
  ) do |format|
    options.output_format = format
  end


  o.on("-x", "--stats",   "get statistics")            { |v| options.stats         = v }
  o.on("-v", "--[no-]verbose", "Print Actions")        { |v| options.verbose       = v; options.show_warnings = v}
  o.on("-g", "--grid",    "For the whole Grid")        { |v| options.grid          = v }
  o.on("-w", "--[no-]warnings",    "Show warnings")    { |v| options.show_warnings = v }

  o.on("-r", "--remote host1,host2,host3",
  "Apply command to dispatcher on remote host(s)",
  "  unlimited number of hosts can be specified; however,",
  "  they must be comma seperated without spaces") do |host|
    options.remote_hosts = host.split(',')
  end


  o.separator ""
  o.on_tail("-h", "--help", "Show this help message.") { |v| options.help = v }

  begin
    o.parse!
  rescue Exception => e
    ERROR(["Command-line Parse Error: #{e}"])
    is_good       = false
    options.debug = true
    options.help  = true
    return_value  = -1
  end

end

if options.debug
  require 'pp'
  puts
  puts "The command-line options structure:"
  pp options
  puts
  puts "The remaining command-line arguments from ARGV:"
  pp ARGV
  puts
end

if options.help
  puts
  puts o
  puts
  puts "The following configuration files are available with the '-f' parameter:"
  puts
  etc_ise = $ISE_ROOT + 'etc' + 'ISE'
  etc_ise.children.each do |a_file|
    puts "\t-f #{a_file.basename}" if '.conf' == a_file.extname
  end
  puts
  exit
end


unless is_good
  exit return_value
end




############################################################################
## At this point ARGV has been processed.  Anything on the command line that
## was not accounted for in the options remains in ARGV


$verbose = options.verbose ? true : false
$debug   = options.debug   ? true : false
$grid    = options.grid

$debug   = true if $DEBUG   ## Allow global scope to over-ride local
$verbose = true if $VERBOSE ## Allow global scope to over-ride local

# Check that this localhost computer is regristered in the Nodes table
# of the IseDatabase.

unless IseDrone.exist?
  IseDrone.register
end







##############################
## Kill a specific run

if options.kill_run
    d = IseDispatcher.new
    d.kill_run options.kill_run
end

##########################################
## Kill a model; but, what does "model"
## mean.  Is it a specifi run_peer_id or
## is it all instances of a model_id within a run
## or is it all instances of a model_id across all runs

if options.kill_model
    d = IseDispatcher.new  unless d
    d.kill_model options.kill_model
end



######################################################
## Start an IseDispatcher instance on either the
## localhost, or if --grid is specified a list of
## remote hosts provided by --remote or the $ISE_CLUSTER
##
##  Examples:
##
##    dispatcher --start
##    dispatcher --start --grid
##    dispatcher --start --grid --remote pcig24,LabPC103
##

if options.start

  if options.grid != true
    d = IseDispatcher.new
    d.conf(options.conf_file)
    d.start
  elsif options.remote_hosts
    options.remote_hosts.each do |node|
      d = IseDispatcher.new(node)
      d.conf(options.conf_file)
      d.start
    end
  else
    $ISE_CLUSTER.each do |node|
        puts "Starting on Cluster node: " + node + " of {#$ISE_CLUSTER}"
      d = IseDispatcher.new(node)
      d.conf(options.conf_file)
      d.start
    end

    IseDispatcher.anneal

  end

end

###############################################################
## Stop ISE dispatchers running on the localhost, remote hosts
## or the $ISE_CLUSER
##
##  Examples:
##
##    dispatcher --stop
##    dispatcher --stop --grid
##    dispatcher --stop --grid --remote pcig24,LabPC103
##


if options.stop

  if options.grid != true
    d = IseDispatcher.new
    d.kill
  elsif options.remote_hosts
    options.remote_hosts.each do |node|
      d = IseDispatcher.new(node)
      d.kill
      sleep 1  # SMELL: is it really necessary to slow down to take a load off the database
    end
  else
    IseDispatcher.killcluster
  end

end


###############################################################
## Kill ISE dispatchers running on the localhost, remote hosts
## or the $ISE_CLUSER
##
##  Examples:
##
##    dispatcher --kill localhost  | same as => dispatcher --stop
##    dispatcher --kill cluster    | same as => dispatcher --stop --grid
##    dispatcher --kill all
##


if options.kill_scope

  case options.kill_scope.to_s
  when "localhost" then
    d = IseDispatcher.new
    d.kill
  when "cluster" then
    IseDispatcher.killcluster
  when "all" then
    # FIXME: Add an "Are you sure?" watchdog
    IseDispatcher.killall
  end

end




######################################################
## Stats returns ISE dispatcher statistics report
##
##  Examples:
##
##    dispatcher --stats
##    dispatcher --stats --grid
##    dispatcher --stats --grid --remote pcig24,LabPC103
##

if options.stats

  if options.grid != true
    d = IseDispatcher.new
    d.ident
    d.stats
  elsif options.remote_hosts
    options.remote_hosts.each do |node|
      d = IseDispatcher.new(node)
      d.ident
      d.stats
    end
  else
    $ISE_CLUSTER.each do |node|
      d = IseDispatcher.new(node)
      d.ident
      d.stats
    end
  end
end

######################################################
## Clean

if options.clean
  IseDispatcher.clean
end

######################################################
## List

if options.list
  puts IseDispatcher.list(options.output_format)
end

######################################################
## Anneal

if options.anneal
  IseDispatcher.anneal      ## was: anneal_crash
end

puts "Done." if $verbose

## The End
###############

exit return_value
