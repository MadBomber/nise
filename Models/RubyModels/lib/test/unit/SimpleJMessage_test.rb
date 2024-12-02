#!/usr/bin/env ruby
################################################################
###
##  File: test_SimpleJMessage.rb
##  Desc: unit test for the SimpleJMessage library, Link16Message library and
##        the SpaceTrack message class.
##
#

require 'rubygems'
require 'pp'

require 'SimpleJMessage'
require 'SpaceTrack'

require 'string_mods'

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

###############
## Test Data ##
###############

# This is a SimpleJ message that encapsulates a Link-16 J3.6 Space Track message
# This specific message is used as the default values for the Ruby class SpaceTrack
$j3dot6_hex = '49363c0071c67dce81ce1a010000020000000700000001000f0000000c0b3c02e1ff310600009e8d47a6fd9b790100002a0c1d331a2f01000000260c2900000000000000000000000000000000000000000000000000000000000000dcc7e8bff0d205085900000068910508dcc7e8bf4c9205080000000000000000000000000000'
$j3dot6_raw = $j3dot6_hex.to_characters


# This is a SimpleJ message that encapsulates a Link-16 J2.5 Ground Track message
$j2dot5_hex = '4936460041237dce81ce1f0100000200000006000000020014000000880e820008ff070000009631a1facd0d00000000050000005a0000f803000d000008008000400000920b0200000000007a0581ce1a010000020000000600000002000f000000b42a0100a40ce0ff0000853f0000c0c7ff01000009000000000000000000740a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
$j2dot5_raw = $j2dot5_hex.to_characters

######################
## Utility Routines ##
######################



#############################################
## Test class for the IseScenario library

class TestSimpleJMessage < Test::Unit::TestCase
  
  def setup
    $debug = false
  end
  
  def teardown
  end



  ###############################
  def test_10_simplej_header
    
    sjh_raw = $j3dot6_raw[0, $simplej_header_length]
    $sjh = SimpleJHeader.new(sjh_raw)

    assert_equal sjh_raw, $sjh.raw, 'Stored @raw is same as input for SimpleJHeader class.'
    assert_equal 11, $sjh.msg_items.length, 'There are 11 items in the Simple-J header.'
    
    puts $sjh
    
  end ## end of def test_10_simplej_header
  
  #################################
  def test_11_simplej_link16_header
    
    sjl16h_raw = $j3dot6_raw[$simplej_header_length, $simplej_link16_header_length]
    $sjl16h = SimpleJLink16Header.new(sjl16h_raw)
    
    assert_equal sjl16h_raw, $sjl16h.raw, 'Stored @raw is same as input for SimpleJLink16Header class.'
    assert_equal 15, $sjl16h.word_count_, 'The SpaceTrack message should be 15 (16-bit) words long.'
    assert_equal 9, $sjl16h.msg_items.length, 'There are 9 items in the Simple-J Link-16 header.'
    
    puts $sjl16h
    
  end ## end of def test_11_simplej_link16_header

  
  #####################
  def test_20_something
  
    sjm = SimpleJMessage.new SpaceTrack
    
    pp sjm
    
    xyzzy = sjm.pack_message
    
    puts "Mine:  " + xyzzy.to_hex
    puts "Given: " + $j3dot6_hex
    
    assert_equal xyzzy, sjm.out, "Returned data should the same as the out attribute."

#    puts sjm
  
  end


end ## end of class TestSimpleJMessage

