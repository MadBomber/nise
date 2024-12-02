#!/usr/bin/env ruby
##########################################################
###
##  File: peerj_debug_helper.rb
##  Desc: add some Java debug stuff to the peerj command line
##        if conditions are met.
#

require 'pathname'

debug_parameters = ""

# TODO: check for exist of $MCC_DEBUG_PORT_FILE
#       if not there, do not set java debug stuff.

if ENV['MCC_DEBUG_PORT_FILE']

  debug_port_path = Pathname.new ENV['MCC_DEBUG_PORT_FILE']
  
  # TODO: if there, then get content of environment variable as a full path
  #       to a file.  If the file does not exist don't do anything

  if debug_port_path.exist?
    
    # TODO: if file exists, then 1) get content; 2) increment by 1;
    #       3) write back to file; 4) set java debug stuff

    debugger_port = debug_port_path.read.to_i + 1
    
    debug_port_file = File.open(debug_port_path.to_s, "w")
    debug_port_file.write debugger_port
    debug_port_file.close

    debug_parameters = "-Xdebug -Xrunjdwp:transport=dt_socket,address=#{debugger_port},server=y,suspend=n"
#   else
#     puts "no file"
  end

# else
#   puts "no env"
end

puts debug_parameters

