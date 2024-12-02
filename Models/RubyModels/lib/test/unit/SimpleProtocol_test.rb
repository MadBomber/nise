#!/usr/bin/env ruby
################################################################
###
##  File: test_SimpleJ.rb
##  Desc: unit test for the SimpleJ library, Link16Message library and
##        the SpaceTrack message class.
##
#

require 'rubygems'
require 'pp'
require 'ap'

require 'SimpleProtocol'
require 'SpaceTrack'
require 'AirTrack'

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


# This is a SimpleJ message that encapsulates a Link-16 J3.2 Air Track message
$j3dot2_hex = '49363c0023007dce81ce1a010000020000000700000001000f0000000c09080400c0201c1800b2929fc8cc0c0200000005600000000000f83f00020a'
$j3dot2_raw = $j3dot2_hex.to_characters



######################
## Utility Routines ##
######################

def type(member_sym, v_bin_str)

  given_value   = Integer('0b' + v_bin_str)
  actual_value  = $st.instance_variable_get("@#{member_sym}") 
  
  unless given_value == actual_value
    puts "WARNING: Testing value of #{member_sym}"
    puts "         Expected: #{given_value}  Got: #{actual_value}"
  end

  $type_cnt += 1

end ## end of def type(member_sym, v_bin_str)

#############################################
## Test class for the IseScenario library

class TestSimpleJ < Test::Unit::TestCase
  
  def setup
    $debug = false
  end
  
  def teardown
  end
  
  ################################
  def test_00_ground_track_message

    assert true
    return nil

    puts "test_00_ground_track__message"
    puts "-"*30
    sjh_raw = $j2dot5_raw[0, $simplej_header_length]
    puts sjh_raw.to_hex
    sjh = SimpleJHeader.new(sjh_raw)
    pp sjh
    puts sjh
    
    puts "-"*30
    next_junk = $j2dot5_raw[$simplej_header_length, 9999]
    sjl16h = SimpleJLink16Header.new(next_junk)
    
    pp sjl16h
    puts sjl16h

  end ## end of def

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
    
  end ## end of def
  
  ###############################
  def test_12_space_track_message

    l16_raw = $j3dot6_raw[$simplej_header_length + $simplej_link16_header_length, 9999]

    st_raw = l16_raw[0,$sjl16h.word_count_*2]
    
    $st = SpaceTrack.new
    
    assert_equal (29+4), $st.msg_items.length, 'There are 29 items in the SpaceTrack message plus 4 from the Link-16 common items.'
    
    $st.raw = st_raw
    
    assert_equal st_raw, $st.raw, 'Stored @raw is same as input for SpaceTrack class.'
    
    $st.unpack_message
    
    $type_cnt = 0
    
    # Link-16 common
	  type(:word_format_,           '00')
	  type(:label_j_series_,        '00011')
	  type(:sublabel_j_series_,     '110')
	  type(:message_len_indicator_, '010')

    # These 'type' statments were taken directly from the SpaceTrack class 

    ###############################
    # J3.6/i
    type(:disused_,            '0')
    type(:force_tell_,         '0')
    type(:special_proc_,       '0')
    type(:sim_indic_,          '0')
    type(:space_indic_,        '0')

#    type(:tn_ls_3_bit_,        '000')     # unitID least significant character
#    type(:tn_mid_3_bit_,       '000')     # unitID next significant character
#    type(:tn_ms_3_bit_,        '001')     # unitID most significant character
#    type(:tn_ls_5_bit_,        '10011')   # 0x13; // "M" -=> Missile
#    type(:tn_ms_5_bit_,        '10111')   # 0x17; // "R" -=> Red

    type(:track_number_reference_, '10111_10011_000_000_000')   # 'RM000'

    type(:minute_,             '111111')
    type(:second_,             '111111')
    type(:track_quality_,      '0111')
    type(:identity_,           '0011')
    type(:space_platform_,     '000000')
    type(:space_activ_,        '0000000')
    type(:unused0_,            '0000000000')

    ###############################
    # J3.6/e0

    # NOTE: x,y,z AND vx, vy, vz are in FEET

    type(:word_format1_,       '10')
    type(:x_position_,         '00100011110001101100111') # scale(x,  0.1,      0x800000);
    type(:x_velocity_,         '11111011010011')          # scale(vx, 1.0/3.33, 0x2000);
    type(:y_position_,         '00000101111001100110111') # scale(y,  0.1,      0x800000);
    type(:space_amplification_,'00000')
    type(:amplification_conf_, '000')
    type(:unused1_,            '0000000000')

    ###############################
    # J3.6/e1
    type(:word_format2_,       '10')
    type(:y_velocity_,         '00001100001010')          # scale(vy, 1.0/3.33, 0x2000);
    type(:z_position_,         '00110100011001100011101') # scale(z,  0.1,      0x800000);
    type(:z_velocity_,         '00001001011110')          # scale(vz, 1.0/3.33, 0x2000);
    type(:lost_track_,         '0')
    type(:boost_indicator_,    '0')
    type(:data_indicator_,     '000')
    type(:spare_,              '000000000000')
    type(:unused2_,            '0000000000')

	  
	  # Space Track specific
	  
	  assert_equal (29+4), $type_cnt, 'Should have tested the value for 33 elements of the Spack Track message.'

    puts $st
    
  end ## end of def test_10_space_track_message


  ##############################
  def test_20_air_track_message
  

  
    puts "Working on AirTrack"
    puts "===================\n\n"
    
    sjh_raw = $j3dot2_raw[0, $simplej_header_length]
    $sjh = SimpleJHeader.new(sjh_raw)
    
    puts "Simple-J Header:"
    puts $sjh
    

    sjl16h_raw = $j3dot2_raw[$simplej_header_length, $simplej_link16_header_length]
    $sjl16h = SimpleJLink16Header.new(sjl16h_raw)
    
    puts "Link-16 Header:"
    puts $sjl16h

    l16_raw = $j3dot2_raw[$simplej_header_length + $simplej_link16_header_length, 9999]

    air_raw = l16_raw[0,$sjl16h.word_count_*2]
    
    $air = AirTrack.new
    $air.raw = air_raw
    $air.out = air_raw
    $air.unpack_message
    
    puts "Air Track:"
    puts $air

  end

end ## end of class TestSimpleJ

