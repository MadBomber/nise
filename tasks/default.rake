##################################################################
###
##  File: default.rake
##  Desc: Defines the :default method for rake.  The :default
##        method is the one executed when rake is called without
##        any command line parameters.
#

require 'systemu'   # used to support external scripting

desc "Build the ISE System"
task :default => ['bundle:install'] do
  puts "Doing a complete build of ISE; this will take a few minutes ..."
  a,b,c = systemu( "iserelease.s" )
  
  unless b.include?( 'Error Count:   0' )
    raise 'Compile ERRORS found; see the file: Release.log'
  end
  
end

