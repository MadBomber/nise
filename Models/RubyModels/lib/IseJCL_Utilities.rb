#########################################################################
###
##  IseJCL_Utilities: Supports IseJCL and IseDatabase
##
##

#require 'pathname'      ## StdLib: Cross-platform File and Directory
require 'pathname_mods' ## Modifications to the StdLib class Pathname
require 'pp'            ## StdLib: supports pretty printing of raw values like the inspect method


def print_file(a_filename)

  file_name = a_filename.class.to_s == 'String' ? a_filename : a_filename.to_s

  begin
    file = File.new(file_name, "r")
    while (line = file.gets)
      puts "#{line}"
    end
    file.close
  rescue => err
    puts "Exception: #{err}"
  end

end


def dump_environment


  require "rbconfig"
  include Config

  puts "=================================================="
  puts "== database.yml supports both cmd-line & rails"
  database_yml = Pathname.new(ENV['RAILS_ROOT']) + 'config' + 'database.yml'
  puts "== #{database_yml.to_s}"
  puts
  print_file database_yml

  puts
  puts "=================================================="
  puts "== config.yml supports only rails"
  config_yml = Pathname.new(ENV['RAILS_ROOT']) + 'config' + 'config.yml'
  puts "== #{config_yml.to_s}"
  puts
  print_file config_yml

  puts
  puts "=================================================="
  puts "== CONFIG environment:"
  puts
  pp CONFIG

  puts
  puts "=================================================="
  puts "== ENV environment:"
  puts
  pp ENV

  puts
  puts "=================================================="
  puts "== Items of interest from CONFIG and ENV:"
  puts
  puts "ENV:    HOSTNAME ........ #{ENV['HOSTNAME']}"
  puts "ENV:    IPADDRESS ....... #{ENV['IPADDRESS']}"
  puts "ENV:    USERNAME ........ #{ENV['USERNAME']}"
  puts "ENV:    LOGNAME ......... #{ENV['LOGNAME']}"
  puts "ENV:    USER ............ #{ENV['USER']}"
  puts
  puts "ENV:    ISE_QUEEN ....... #{ENV['ISE_QUEEN']}"
  puts "ENV:    ISE_DBNAME ...... #{ENV['ISE_DBNAME']}"
  puts
  puts "ENV:    ISE_GATEWAY ..... #{ENV['ISE_GATEWAY']}"
  puts "ENV:    ISE_PORT ........ #{ENV['ISE_PORT']}"
  puts
  puts "ENV:    ISE_CLUSTER ..... #{ENV['ISE_CLUSTER']}"
  puts "ENV:    ISE_GRID ........ #{ENV['ISE_GRID']}"
  puts
  puts "ENV:    ISE_ROOT ........ #{ENV['ISE_ROOT']}"
  puts "ENV:    ISE_RUN ......... #{ENV['ISE_RUN']}"
  puts "ENV:    ISE_RUN_INPUT ... #{ENV['ISE_RUN_INPUT']}"
  puts "ENV:    ISE_RUN_OUTPUT .. #{ENV['ISE_RUN_OUTPUT']}"
  puts
  puts "ENV:    ISE_ENV ......... #{ENV['ISE_ENV']}"
  puts
  puts "=================================================="
  puts "== Ruby Environment"
  puts
  puts "Kernal: RUBY_PLATFORM ... #{RUBY_PLATFORM}"
  puts
  puts "CONFIG: ruby_version .... #{CONFIG['ruby_version']}"
  puts "CONFIG: arch ............ #{CONFIG['arch']}"
  puts "CONFIG: host ............ #{CONFIG['host']}"
  puts "CONFIG: target_vendor ... #{CONFIG['target_vendor']}"
  puts "CONFIG: host_vendor ..... #{CONFIG['host_vendor']}"
  puts
  puts "ENV:    RUBYLIB ......... #{ENV['RUBYLIB']}"
  puts
  puts "=================================================="
  puts "== Rails Environment"
  puts
  puts "ENV:    RAILS_ROOT ..... #{ENV['RAILS_ROOT']}"
  puts "ENV:    RAILS_ENV ...... #{ENV['RAILS_ENV']}"
  puts
  puts "=================================================="
  puts "== GEM Environment"
  puts
  if RUBY_PLATFORM.include?('mswin32')
    system 'call gem environment'
  else
    system 'gem environment'
  end
  puts
  puts "== bundle check"
  system "cd #{ENV['ISE_ROOT']}; bundle check"  ## SMELL: Maynot be cross-platform
  puts
  
  puts "=================================================="
  puts "== ohai report"
  system 'ohai'

  puts

  return nil

end


###############################################
## global function to isolate location of error
## within the user supplied DSL script.

def comefrom
  return caller.last
end


###########################################################
## global function to display an error
## TODO: Consider replacing with standard Ruby/ActiveRecord Logger class

# adds ability to get the name of the calling method
module Kernel
  private
  def this_method    ## SMELL: This technique will be OBE with Ruby 1.9.x +
    caller[0] =~ /`([^']*)'/ and $1
  end
end

# A generic logging feature to tie messages to specific lines on user input
# a_msg_str can be either a string variable, literal, or an array of string variables or literals
def my_logger(a_type_str, a_msg_str)
  puts "#{a_type_str}:\t" + comefrom
  [a_msg_str].flatten.each { |a_str| puts "\t" + a_str }
  if (defined? $LOG_COUNTS)
    unless $LOG_COUNTS.key?(a_type_str)
      $LOG_COUNTS[a_type_str] = 0
    end
    $LOG_COUNTS[a_type_str] += 1
  else
    $LOG_COUNTS = Hash.new
    $LOG_COUNTS[a_type_str] = 1
  end

  return nil
end

# Prints the total number of each log message type
def print_log_counts

  unless $LOG_COUNTS.nil?
    puts "\nLog Messages Statistics:\n"

    $LOG_COUNTS.each_key do |k|
        puts "\t#{$LOG_COUNTS[k]}\t#{k}"
    end
  end

  return nil

end

# resets the log counts back to zero
def reset_log_counts
  if (defined? $LOG_COUNTS)
    $LOG_COUNTS.each_key do |k|
      $LOG_COUNTS[k] = 0
    end
  else
    $LOG_COUNTS = Hash.new
  end
  return nil
end


def ERROR(a_string)
  my_logger(this_method, a_string)
end

def WARNING(a_string)
  my_logger(this_method, a_string) if $VERBOSE || $DEBUG || $verbose || $verbose
end

def INFO(a_string)
  my_logger(this_method, a_string) if $VERBOSE || $DEBUG || $verbose || $verbose
end

def DEBUG(a_string)
  my_logger(this_method, a_string) if $DEBUG
end

def STUB(a_string)
  my_logger(this_method, a_string) if $DEBUG
end


###################################################
## Extend the base Array class to incorporate the
## new columnize method for pretty printing data.
## The use of the vertical bar makes this method
## interesting for interface with the ISEwiki (TWiki)

class Array

  protected

  def columnized_row(fields, sized)
    r = []
    fields.each_with_index do |f, i|
      r << sprintf("| %0-#{sized[i]}s",
      f.to_s.gsub(/\n|\r/, "").slice(0, sized[i]))
    end
    r << "|"
    r.join(" ")
  end

  public

  def columnized(options = {})
    sized = {}
    self.each do |row|
      row.attributes.values.each_with_index do |value, i|
        sized[i] = [sized[i].to_i, row.attributes.keys[i].length, value.to_s.length].max
        sized[i] = [options[:max_width], sized[i].to_i].min if options[:max_width]
      end
    end

    table = []
    table << header = columnized_row(self.first.attributes.keys, sized)
    ##  table << header.gsub(/./, "-")  ## draws a ;ine od dashs the same length as header
    self.each { |row| table << columnized_row(row.attributes.values, sized) }
    table.join("\n")
  end
end

#################################################################
## Validate System Environment Variable

def is_env_good? (var_name, default_value=nil, valid_values=nil)

  DEBUG(["Checking validity of environment variable: #{var_name}"])

  is_good = (ENV[var_name]) ? true : false
  unless is_good
    if default_value
      WARNING([
        "System environment variable #{var_name} is not defined.",
      "Defaulting to: #{default_value}" ])
      ENV[var_name] = default_value
      is_good = true
    else
      ERROR(["System environment variable #{var_name} is not defined."])
    end
  end
  if valid_values
    is_good = [valid_values].flatten.include?(ENV[var_name])
    unless is_good
      WARNING([
        "System environment variable #{var_name} is not defined.",
        "Defaulting to: #{default_value}",
        "Valid Values:  #{valid_values}"
      ])
      ENV[var_name] = default_value
      is_good = true
    end
  end
  return is_good
end


#################################################################
## Establish and Validate the ISE Environment
## may not return if the validation files problems

def establish_and_validate_environment

  ise_good  = true  ## Assume the environment is good; then prove it is not

  $DEBUG   = ARGV.include? "--debug"   unless $DEBUG    ## allows programmer to set $DEBUG internally
  $VERBOSE = ARGV.include? "--verbose" unless $VERBOSE  ## allows programmer to set $VERBOSE internally

  ####################################################
  # Global OS-level "Constants"

  $DEFAULT_DOMAIN          = '.lmmfc-vrsil.com'   # FIXME: Hardcoded default domain name; get it from $HOSTNAME
  $HOSTNAME                = ENV['HOSTNAME']

  ####################################################
  # Global Environment "Constants"

  $DEFAULT_ENVIRONMENT = 'development'

  $VALID_ENVIRONMENTS  = ['development',    # working on localhost
                          'test',           # integration testing
                          'staging',        # acceptance testing
                          'production']     # live

  ############################
  # Environment Variables Used

  if RUBY_PLATFORM.include?('mswin32') then
    ENV['USER'] = ENV['USERNAME']   ## MS Windows CMD shell (and powershell) are different from linux and cygwin
  end

  unless ENV['USER'].to_s.length > 0
    ENV['USER'] = 'unknown'
    WARNING(["System environment variable USER is not defined.",
    "Defaulting to: " + ENV['USER'] ])
  end

#  ise_good = is_env_good?('ACE_ROOT') && ise_good

  ise_good = is_env_good?('ISE_ROOT') && ise_good
  ise_good = is_env_good?('ISE_QUEEN',    'localhost') && ise_good
  ise_good = is_env_good?('ISE_GATEWAY',  'localhost') && ise_good
  ise_good = is_env_good?('ISE_ENV',      $DEFAULT_ENVIRONMENT, $VALID_ENVIRONMENTS)  && ise_good
  ise_good = is_env_good?('RAILS_ENV',    ENV['ISE_ENV'], $VALID_ENVIRONMENTS) && ise_good

  $ISE_GOOD = ise_good

  return ise_good unless ise_good       ## short-circuit if not good so far

  ##########################################
  ## Validate required directory variables
  ## All path variable should be expressed as absolute

  $ISE_ROOT = Pathname.new(ENV['ISE_ROOT']).realpath    # root path of the ISE distribution

  unless $ISE_ROOT.exist? && $ISE_ROOT.directory?

    ise_good = false

    ERROR(["The ISE_ROOT environment variable is not correctly defined.",
      "ISE_ROOT points to the top of the ISE distribution.",
      "The 'setup_symbols' script should be executed to establish",
      "the proper environment within which ISE functions.",
      "  Value of ISE_ROOT is: #{$ISE_ROOT}"])

  end


  $RAILS_ROOT = Pathname.new(ENV['RAILS_ROOT']).realpath        # root path to the RubyOnRails Portal for ISE


  ##########################################
  ## Validate optional directory variables

  optional_dir_var = ["ISE_RUN", "ISE_RUN_INPUT", "ISE_RUN_OUTPUT"]

  optional_dir_var.each do | odv |
    if ENV[odv]
      odv_dir = Pathname.new(ENV[odv]).realpath
      unless odv_dir.exist? and odv_dir.directory?
        ise_good = false && ise_good
        ERROR(["The system environment variable #{odv} was specified; however,",
               "it does not point to a valid directory.",
               "  #{odv} value: #{ENV[odv]}"])
      end
    end
  end

  $ISE_GOOD = ise_good

  return ise_good unless ise_good       ## short-circuit if not good so far

  ##########################################
  ## Validate optional environment variables




  ####################
  # Global "Constants"

  $ISE_ENV     = ENV['ISE_ENV']                   # Same use as RAILS_ENV
  $RAILS_ENV   = ENV['RAILS_ENV']                 # May be unnecessary

  $USER        = ENV['USER']                      # the login name of the user executing this stuff
  $ISE_QUEEN   = ENV['ISE_QUEEN']                 # the IP address of the IseQueen
  $ISE_GATEWAY = ENV['ISE_GATEWAY']               # the IP address of the IseNode that has an IseDispatcher
                                                  # ... used in support of IseModels running on MS Windows platforms

  $ISE_CLUSTER = ENV['ISE_CLUSTER'] ? ENV['ISE_CLUSTER'].split : [] ## Part of the ISE grid
  $ISE_GRID    = ENV['ISE_GRID'] ? ENV['ISE_GRID'] : nil            ## Grid segment name -- Sun Grid Engine

  $ISE_RUN        = ENV["ISE_RUN"]         ? Pathname.new(ENV["ISE_RUN"]).realpath        : nil
  $ISE_RUN_INPUT  = ENV["ISE_RUN_INPUT"]   ? Pathname.new(ENV["ISE_RUN_INPUT"]).realpath  : nil
  $ISE_RUN_OUTPUT = ENV["ISE_RUN_OUTPUT"]  ? Pathname.new(ENV["ISE_RUN_OUTPUT"]).realpath : nil


  $ISE_GOOD = ise_good

  return $ISE_GOOD

end

##########################################################
## Validate the ISE_DEFAULT_JOB

def validate_ise_default_job

  $DEBUG=true

  if ENV['ISE_DEFAULT_JOB']

    idj = ENV['ISE_DEFAULT_JOB']

    # determine if its a Job.id or a Job.name

    a_num = idj.to_i

    if a_num > 0 && a_num.to_s == idj
      # it is a Job.id
      idj = a_num
    end

#    begin
      $ISE_DEFAULT_JOB = case idj.class.to_s
        when "String" then Job.find_by_name(idj)
        when "Fixnum" then Job.find(idj)
        else nil
      end ## end of case
#    rescue
#      $ISE_DEFAULT_JOB = nil
#    end

    unless $ISE_DEFAULT_JOB
      ERROR(["The system environment variable ISE_DEFAULT_JOB was defined",
               "as: #{ENV['ISE_DEFAULT_JOB']}",
               "However, no such IseJob is currently registered."])
    end

  else
    $ISE_DEFAULT_JOB = nil
  end

  $DEBUG=false

end   ## end of validate_ise_default_job


##########################################################
## Validate the ISE_CLUSTER

def validate_ise_cluster

  ise_good = true

  if $ISE_CLUSTER.length > 1
    $ISE_CLUSTER.each do | drone |
      node = Node.find_by_name(drone)
      unless node
        WARNING(["The system environment variable ISE_CLUSTER contains an unknown IseDrone.",
               "Bad IseDrone named #{drone} has been removed."])
        ise_good = false && ise_good
      end
    end
  end

  return ise_good

end ## end of validate_ise_cluster


##########################################################
## where_is takes a platform then gets the relevant
## load library path and a DLL name.  The method returns
## an array of the places (as full pathnames) where the
## DLL was found.
##
## a_platform can be a string or of class Platform
## a_file can be a string or pf class Pathname
##    if string, append lib prefix and lib suffix
##    if Pathname, assume that the 'fix is in
##
##  Returns nil when an error is incountered
##  Otherwise returns an array of Pathname
#

    # FIXME: where_is assumes that "this" execution platform is same as platform specified for model.
    # SMELL: Assumes a homogenious cluster
    # TODO:  Consider case of a hetrogenious cluser where this script is being run on linux and we're checking a windows model

def where_is(a_platform, a_file)

  its_here = []

  # validate a_platform
  # FIXME: this functionality occurs in at least one other place; not good DRY

  if a_platform.class.to_s == "String"
    unless $VALID_PLATFORMS.include?(a_platform)
      ERROR(["Invalid platform was specified.",
             "THe bad platform string is: #{a_platform}"])
      return nil
    end

    a_platform = Platform.find_by_name(a_platform)

  else
    unless a_platform.class.to_s = "Platform"
      ERROR(["Invalid parameter class for a_platform.  Expecting String or Platform.",
             "THe bad parameter class is: #{a_platform.class}",
             "The bad parameter is: #{a_platform.inspect}"])
      return nil
    end
  end

  ## a_platform is a valid instance of Platform

  env_name = a_platform.lib_path_name

# FIXME; cross-platform can't get access to some other platform's environment variables

  unless ENV[env_name]
    WARNING(["Expecting a system environment variable named: #{env_name}",
           "It is possible this is a cross-platform hetrogenious internal system error",
           "Parameters:",
           "  a_platform: #{a_platform.inspect}",
           "  a_file:     #{a_file.inspect}"])
    return nil
  end

  lib_paths = ENV[env_name].split(a_platform.lib_path_sep)

  ## Validate the a_file parameter

  a_file = a_file.to_s if a_file.class.to_s == "Pathname"

  unless a_file.class.to_s == "String"
#    raise xyzzy
    ERROR(["Invalid parameter class for a_file.  Expected String or Pathname.",
           "The bad parameter class is: #{a_file.class}",
           "The bad parameter is: #{a_file.inspect}"])
    return nil
  end

  # FIXME: Assume that if the prefix is not part of the file that the suffix is not as well

  unless a_platform.lib_prefix.nil?
    unless a_platform.lib_prefix == a_file.slice(1, a_platform.lib_prefix.length)
      a_file = a_platform.lib_prefix + a_file + a_platform.lib_suffix
    end
  end

  # a_file is now a string with the appropriate prefix and suffix for the platform

  lib_paths = ENV[a_platform.lib_path_name].split(a_platform.lib_path_sep)

  lib_paths.each do | path |
    a_full_path = Pathname.new(path) + a_file
    if a_full_path.exist?
      its_here += [a_full_path]
    end
  end

  return its_here

end

