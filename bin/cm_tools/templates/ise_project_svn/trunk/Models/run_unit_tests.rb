#!/usr/bin/env ruby
#############################################################################
###
##  File: run_unit_tests.rb
##  Desc: Executes all test programs at this directory and below
##        A test program is one who's name is in the form:
##            test_*.rb
#
require 'rubygems'
require 'systemu'
require 'term/ansicolor'

class String
  include Term::ANSIColor
end


# SMELL: use if 'find' command may not be cross platform
return_code, std_output, std_error = systemu("find . -name 'test_*.rb'")

test_programs = std_output.split("\n")

pass_cnt    = 0
fail_cnt    = 0

puts

test_programs.each do |tp|
  printf "%s ... ", tp.split('/').last
  $stdout.flush
  return_code, std_output, std_error = systemu("ruby #{tp}")
  if 0 == return_code
    puts "passed".green
    pass_cnt += 1
  else
    puts "failed rt: #{return_code}".red
    fail_cnt += 1
  end
end

puts
puts "RECAP".bold.underline
puts "  Passed: ".green + "#{pass_cnt}"
puts "  Failed: ".red + "#{fail_cnt}"
puts

