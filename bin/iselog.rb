#!/usr/bin/env ruby
##################################################
##  File:  iselog.rb
##  Desc:  Provides ability to add to the ISE::Log from shell scripts
##         Use the system environment variables ISE_LOG and ISE_LOG_LEVEL
##         if you do not want the defaults.
#

require 'ise_logger'

default_my_level='INFO'

ISE::Log.new
ISE::Log.progname="iselog"

my_level = ARGV.shift.upcase

unless ISE::VALID_LOG_LEVELS.include?(my_level)
  ARGV.unshift(my_level)
  my_level = default_my_level
end

my_level.downcase!
my_msg = ENV['USER'] + ': ' + ARGV.join(' ')

ISE::Log.send(my_level, my_msg)

