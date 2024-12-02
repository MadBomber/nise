#!/usr/bin/env ruby
########################################################
## Execute an IseJob on an IseCluster

require 'rubygems'    # needed by Ruby 1.8.7
require 'optparse'    # STDLIB: command line option parser

cmd_line = ARGV.dup




##########################################################################################################
##########################################################################################################
#  Start of main processing
##########################################################################################################
##########################################################################################################




# $DEBUG and $VERBOSE are set in IseJCL_Utilities based upon --debug and --verbose cmd line parameters

$debug_flags  = "x"
#$debug_flags += ":DB"   #  Database Layer
#$debug_flags += ":OBJ"  #  Object Manager
#$debug_flags += ":PH"    #  Peer Handler

$debug_flags += ":MDL"  #  User Model
$debug_flags += ":APP"  #  Application
$debug_flags += ":APB"  #  Application Base

#$debug_flags += ":NET"
#$debug_flags += ":ALL"
#puts "DEBUG = #{$debug_flags}"




########
# default options
options = {
  :debug       => false,
  :list        => false,
  :config      => 0,        # zero is not a valid IseJob
  :config_name => nil,      # used with the -n option
  :truncate    => false,
  :verbose     => false,
  :purge       => false,
  :kill_run    => false,
  :kill_model  => false,
  :kill_job    => false,    # used to delete an IseJob
  :grid        => false,
  :logstate    => false,
  :dryrun      => false,
  :rerun       => 0,
  :force       => false
}

#puts "arguments: #{ARGV}"
#puts "Number of arguments: #{ARGV.size}"

if ARGV.size == 0 then
  options[:jobs] = true
else
 ARGV.options do |o|
  script_name = File.basename($0)

  o.set_summary_indent('  ')
  o.banner =    "Usage: #{script_name} [options]"
  o.define_head "ISE run script"
  o.separator   ""
  o.separator   "Mandatory arguments to long options are mandatory for short options too."

  # TODO: Add --output and --input options to allow for over-ride of $ISE_RUN

  o.on("-c", "--config=val", Integer, "Configuration ID to load")    { |v| options[:config] = v }
  o.on("-n", "--name=val",   String,  "Configuration Name to load")  { |v| options[:config_name] = v }
  
  o.on("-t", "--truncate", "Truncate Run Tables")     { |v| options[:truncate] = v }
  o.on("--force", "Force the operation; over-ride safe-guards")     { |v| options[:force] = v }
  
  
  o.on("-d", "--debug", "Turn Debug On")              { |v| options[:debug] = v }
  o.on("-v", "--verbose", "Print Actions")            { |v| options[:verbose] = v }
  o.on("--dryrun", "Print what would be done")  { |v| options[:dryrun] = v }
  o.on("--logstate", "Turn on model database state logging")  { |v| options[:logstate] = v }

  o.on("-p", "--purge=val", Integer, "Purge a job that has run") { |v| options[:purge] = v }
  o.on("-g", "--grid", "Submit to Grid")            { |v| options[:grid] = v }
  o.on("--killrun=val", Integer, "kill a given run")         { |v| options[:kill_run] = v }
  o.on("--deletejobconfig", "delete an IseJob configuration given by the -c or -n parameters") { |v| options[:kill_job] = true }
#  o.on("--killmodel=val", "kill a given model")         { |v| options[:kill_model] = v }

  o.on("-l", "--list", "list runs in database")     { |v| options[:list] = v }
  o.on("-j", "--jobs", "list jobs in database")     { |v| options[:jobs] = v }

  o.separator ""
  o.on_tail("-h", "--help", "Show this help message.") do
    puts
    puts o
    puts
    puts "You may also use the 'ise' command like this:"
    puts "  ise your_job_name [options]"
    puts
    puts "Which is shorthand for:"
    puts "  ise -n your_job_name [options]"
    puts
    exit(-1)
  end
  o.parse!
 end
end


#
########


def tell_user_dashj_then_exit(error_message)
  ISE::Log.error error_message
  $stderr.puts
  $stderr.puts "ERROR: #{error_message}"
  $stderr.puts "For a list of IseJobs Use:  ise -j"
  $stderr.puts
  exit(-1)
end


########
#

retval = 0  ## Set return value for this script; positive is the the Run.id; negative is an error

require 'ise_logger'
ISE::Log.new
ISE::Log.info "#{ENV['USER']} executing ISE on Queen: #{ENV['ISE_QUEEN']} with params: #{cmd_line.join(' ')}"

unless 0 == ARGV.length
  options[:config_name] = ARGV[0] if options[:config_name].nil?
end


unless options[:config_name].nil?

  require 'IseRun'

  begin
    my_job = Job.find_by_name( options[:config_name] )
    if my_job
      options[:config]  = my_job.id
    else
      options[:config]  = 0
      out_message = "'#{options[:config_name]}' is an unknown IseJob on this IseQueen: #{ENV['ISE_QUEEN']}"
      tell_user_dashj_then_exit(out_message)
    end

  rescue Exception => e
    out_message = "#{e}"
    ISE::Log.error out_message
    $stderr.puts
    $stderr.puts out_message
    $stderr.puts
    exit(-1)
  end

end ## end of unless options[:config_name].nil?


########################################################################################
if options[:kill_job]

  # If no valid IseJob configuration has been supplied then tell user about ise -j
  unless options[:config] > 0
    out_message = "Failed to provide a valid IseJob for this IseQueen: #{ENV['ISE_QUEEN']}"
    tell_user_dashj_then_exit(out_message)
  end
  
  require 'IseJCL'
  
  begin
    delete_this_job = Job.find(options[:config])
  rescue ActiveRecord::RecordNotFound
    out_message = "Failed to provide a valid IseJob for this IseQueen: #{ENV['ISE_QUEEN']}"
    tell_user_dashj_then_exit(out_message)
  end

  # Check this user against the user who created the IseJob, if don't match suggest the use of --force
  
  this_user   = User.get_me
  owner_user  = User.find(delete_this_job.created_by_user_id)
  
  unless this_user.id == owner_user.id
    unless options[:force]
      error_message = "You are not the creator of IseJob '#{delete_this_job.name}' "
      error_message += "Contact #{owner_user.name} at #{owner_user.phone_number}"
      ISE::Log.error error_message
      $stderr.puts
      $stderr.puts "ERROR: #{error_message}"
      $stderr.puts
      exit(-1)
    else
      ISE::Log.warning "Forcing deletion of IseJob '#{delete_this_job.name}' even though the current user is not the job's creator."
    end
  end
  
  # Check to see if any IseRuns use this configuration, if so, don't delete anything

  runs_for_this_job = Run.all(:conditions => "job_id = #{delete_this_job.id}")
  
  unless runs_for_this_job.empty?
    error_message = "#{runs_for_this_job.length} IseRun(s) still exist for IseJob '#{delete_this_job.name}'"
    error_message += " Delete them using the -t or -p parameter before deleting this IseJob."
    ISE::Log.error error_message
    $stderr.puts
    $stderr.puts "ERROR: #{error_message}"
    $stderr.puts "To see the current runs on IseQueen #{ENV['ISE_QUEEN']} use the command:  ise -l"
    $stderr.puts
    exit(-1)
  end
  
  # Delete the IseJob
  
  puts
  puts "Name: #{delete_this_job.name}"
  puts "Desc: #{delete_this_job.description}"
  puts
  print "Delete this IseJob? Enter 'yes' to delete: "
  answer = gets.chomp
  puts

  if 'yes' == answer
    IseJob.delete(delete_this_job.name)
    out_message = "IseJob '#{delete_this_job.name}' has been removed from the IseDatabase on IseQueen #{ENV['ISE_QUEEN']}"
  else
    out_message = "User aborted the deletion of IseJob '#{delete_this_job.name}' from the IseDatabase on IseQueen #{ENV['ISE_QUEEN']}"
  end

  puts out_message
  ISE::Log.info out_message
  retval = 0

##############################################################################
elsif options[:kill_run]
  require 'IseRun'
  require 'IseDispatcher'
  establish_and_validate_environment  ## from IseJCL_Utilities
  d = IseDispatcher.new
  d.kill_run options[:kill_run]

##############################################################################
elsif options[:kill_model]
  require 'IseRun'
  require 'IseDispatcher'
  establish_and_validate_environment  ## from IseJCL_Utilities
  d = IseDispatcher.new   unless d
  d.kill_model options[:kill_model]

##############################################################################
elsif options[:jobs]
  require 'IseDatabase'
  list_all_jobs
	puts "Queen:   #{$ISE_QUEEN}"
	puts "Cluster: #{$ISE_CLUSTER.join(', ')}"
  exit(retval)

##############################################################################
elsif options[:truncate]
  require 'IseRun'
  establish_and_validate_environment  ## from IseJCL_Utilities
  IseRun.delete_all(options[:force])

##############################################################################
elsif options[:purge]
  require 'IseRun'
  establish_and_validate_environment  ## from IseJCL_Utilities
  puts "Purging Run #{options[:purge]}"
  IseRun.delete(options[:purge].to_i,options[:force])

##############################################################################
elsif options[:list]
  require 'IseRun'
  establish_and_validate_environment  ## from IseJCL_Utilities
  Run.status_report

##############################################################################
elsif options[:kill_run] or options[:kill_model]
  retval = 0

##############################################################################
elsif options[:config] > 0
  require 'IseRun'
  require 'IseDispatcher'
  establish_and_validate_environment  ## from IseJCL_Utilities

  # submit a job on the grid engine
  $GRID = options[:grid] ? true : false

  # model debugging
  $DEBUG_MDL = options[:debug] ? true : false

  # used for echoing the submission process to the screen
  $VERBOSE = options[:verbose] ? true : false

  #individual models to log their state to the database
  $LOGSTATE = options[:logstate] ? true : false

  a = IseRun.new(options[:config])
  a.setup
  
  ise_job_summary                   = Hash.new
  ise_job_summary['run_id']         = a.run.id  
  ise_job_summary['run_created_at'] = a.run.created_at  
  ise_job_summary['run_guid']       = options[:dryrun] ? "Dry Run" : a.run.guid 
  ise_job_summary['job_id']         = a.job.id
  ise_job_summary['job_name']       = a.job.name
  ise_job_summary['job_desc']       = a.job.description
  ise_job_summary['user_name']      = [ a.user.name, a.user.phone_number, a.user.email ]


  options[:dryrun] ? a.dryrun : a.execute
  if $VERBOSE
    puts "IseJob Summary"
    puts "id:   #{a.job.id}"
    puts "name: #{a.job.name}"
    puts "desc: #{a.job.description}"
    puts "guid: #{a.run.guid}" unless options[:dryrun]
  end

else

  $stderr.puts
  $stderr.puts "Try:  ise -h"
  $stderr.puts
  retval = -1
end

exit(retval)   ## A positive value is the Run.id; a negative value is an error?

