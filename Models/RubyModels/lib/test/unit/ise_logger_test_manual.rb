#!/usr/bin/env ruby
#########################################################
###
##  File: test_ise_logger.rb
##  Desc: unit test for the ise_logger library
#

require 'ise_logger'

def test_log
  ISE::Log.debug    "hello debug"
  ISE::Log.info     "hello info"
  ISE::Log.warn     "hello warn"
  ISE::Log.error    "hello error"
  ISE::Log.fatal    "hello fatal"
  ISE::Log.unknown  "hello unknown"
  ISE::Log.xyzzy    "hello xyzzy"
  ISE::Log.error "Testing the << method"
  ISE::Log << "second line\n"
  ISE::Log << "Third line\n"
  ISE::Log.xyzzy    "hello xyzzy"
end

#########################################################################################
puts 'begin tests using the defaults for environment variables ISE_LOG and ISE_LOG_LEVEL'

ENV['ISE_LOG']  = nil
ENV['ISE_LOG_LEVEL']  = nil

ISE::Log.new

test_log

##########################################################################################
puts 'begin tests using the environment variables ISE_LOG and ISE_LOG_LEVEL'

ENV['ISE_LOG']  = 'temp.txt'
ENV['ISE_LOG_LEVEL']  = 'debug'

ISE::Log.new

test_log


##########################################################################################
puts 'begin tests using the environment variables ISE_LOG and ISE_LOG_LEVEL'
puts 'but over-riding them on the constructor'

ENV['ISE_LOG']  = 'temp.txt'
ENV['ISE_LOG_LEVEL']  = 'debug'

ISE::Log.new 'temp2.txt'
ISE::Log.level = IseLogger::FATAL

test_log


##########################################################################################
puts 'begin tests using the environment variables ISE_LOG and ISE_LOG_LEVEL'
puts 'but over-riding them on the constructor'
puts 'this time using $stdout as the over-ride'

ENV['ISE_LOG']        = 'temp.txt'
ENV['ISE_LOG_LEVEL']  = 'debug'

ISE::Log.new $stdout
ISE::Log.level = IseLogger::INFO

test_log



##########################################################################################
puts 'begin tests using the environment variables ISE_LOG and ISE_LOG_LEVEL'
puts '$ISE_LOG is syslog'

ENV['ISE_LOG']  = 'syslog'
ENV['ISE_LOG_LEVEL']  = 'fatal'

ISE::Log.new
ISE::Log.level = IseLogger::INFO

test_log


