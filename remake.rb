#!/usr/bin/env ruby
#######################################################
## Rebuild the make system
##

require 'pathname'          ## StdLib: Cross-platform file system capability
require 'rubygems'          ## StdLib: required to make use of the following GEM packages:
require 'highline/import'   ## GEM: high-level line oriented console interface

is_good = true  ## Assume the working evironment is good; then prove that it is not

unless ARGV.length == 0
  is_good = false
  puts
  puts "Usage: #{Pathname.new($0).basename}"
  puts
end

puts "Checking working environment ..."

unless ENV['ACE_ROOT']
  is_good = false
  puts "ERROR: The system environment variable ACE_ROOT is not defined."
  puts "       Perhaps all you need is to execute the 'setup_symbols' script."
end

unless ENV['ISE_ROOT']
  is_good = false
  puts "ERROR: The system environment variable ISE_ROOT is not defined."
  puts "       Perhaps all you need is to execute the 'setup_symbols' script."
end

unless is_good
  exit
end

## Turn the system environment varibles into paths

ACE_ROOT = Pathname.new(ENV['ACE_ROOT'])
ISE_ROOT = Pathname.new(ENV['ISE_ROOT'])

unless ACE_ROOT.exist? && ACE_ROOT.directory?
  is_good = false
  puts "ERROR: ACE_ROOT bad: #{ACE_ROOT}"
  puts "       The environment variable ACE_ROOT must point to the ACE distribution directory."
end

unless ISE_ROOT.exist? && ISE_ROOT.directory?
  is_good = false
  puts "ERROR: ISE_ROOT bad: #{ISE_ROOT}"
  puts "       The environment variable ISE_ROOT must point to the ISE distribution directory."
end



if RUBY_PLATFORM.downcase.include?("linux") then        ## linux
  make_type = "gnuace"
  platform  = "posix"
elsif RUBY_PLATFORM.downcase.include?("cygwin") then    ## *nix environment on MS Windows
  make_type = "gnuace"
  platform  = "posix"
elsif RUBY_PLATFORM.downcase.include?("darwin") then    ## MacOS X
  make_type = "gnuace"
  platform  = "posix"
elsif RUBY_PLATFORM.downcase.include?("mswin32") then   ## Microsoft Windows Command and Power Shell
  make_type = "vc9"
  platform  = "windows"
else
  puts "ERROR: Platform not supported: #{RUBY_PLATFORM}"
  is_good = false
end

## Check to see if there is a PERL capability on this pig

if platform == "windows"
  unless ENV['PATH'].downcase.include?("perl")
    is_good = false
    puts "ERROR: Perl is not installed or not defined in PATH."
  end
else    ## linux, *nix, MacOS X, cygwin, and other posix systems
  unless system("which perl")  ## SMELL: no sure this will work; need a test
    is_good = false
    puts "ERROR: Perl is not installed."
  end
end

build_tool_path   = ACE_ROOT + "bin" + "mwc.pl"
make_file_path    = ISE_ROOT + "ise.mwc"
include_path      = ISE_ROOT + "MPC"
feature_file_path = include_path + "ISE.features"

unless build_tool_path.exist?
  is_good = false
  puts "ERROR: Build tool not here: #{build_tool_path}"
  puts "       ISE uses the tool #{build_tool_path.basename.to_s} to build its executables and libraries."
end

unless include_path.exist? && include_path.directory?
  is_good = false
  puts "ERROR: Build directory missing: #{include_path}"
end

unless make_file_path.exist?
  is_good = false
  puts "ERROR: Workspace makefile missing: #{make_file_path}"
end

unless feature_file_path.exist?
  is_good = false
  puts "ERROR: Feature file missing: #(feature_file_path)"
end

unless is_good
  puts
  puts "... errors were found.  Terminating."
  exit
end

# TODO: Pathname.pwd on windows uses forward slashes whereas ISE_ROOT has backslashes
# Need to work around this windows problem; maybe something like
# current_working_dir = substitute '\' for '/' in Pathname.pwd
unless Pathname.pwd.realpath == ISE_ROOT.realpath
  say("<%= color('WARNING:', :black, :on_yellow) %> ")
  puts "Your current working directory (CWD) is not the same as the ISE_ROOT."
  puts "         ISE_ROOT: #{ISE_ROOT}"
  puts "         CWD:      #{Pathname.pwd}"
  puts
  unless agree("Do you want to continue?")
    puts "... terminating."
    exit
  end
end

######################################
## Environment is safe to work in

puts "... working environment is acceptable."

include_str = "-include " + include_path.to_s
feature_str = "-feature_file " + feature_file_path.to_s
type_str    = "-type " + make_type

sys_str = "perl " + build_tool_path.to_s + " " + type_str + " " + include_str + " " + feature_str + " " + make_file_path.to_s

puts sys_str

system sys_str
