#!/usr/bin/env ruby
#####################################################################
###
##  File:  test_string_mods.rb
##  Desc:  Unit testing C-ish Pascal-ish to_* and from_* methods added to the
##         String class.
#

require 'string_mods'

require 'pp'
require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

class TestStringMods < Test::Unit::TestCase


  ###############################################################
  def test_to_cstring
    test_string     = "test"
    expected_string = "test\000"
    
    buffer  = test_string.to_cstring
    
    assert_equal expected_string, buffer, "The buffer has a null character at the end"
    assert_equal "\000", buffer[-1,1],    "The last character in the buffer is a null"
    assert_equal 4, test_string.length,   "length of test_string remains unchanged"
    assert_equal 5, buffer.length,        "length of buffer is 1 greater than test_string"

  end


  ###############################################################
  def test_from_cstring
    
    test_string     = "test\000"    # The last character of a cstring is a null character
    expected_string = "test"
    
    thing1  = test_string.from_cstring
    
    assert_equal 'String', thing1.class.to_s, "class is String"
    assert_equal expected_string, thing1,     "unpacked value is the same as the packed value"
    
    assert_equal 4, thing1.length
    
  end



  ###############################################################
  def test_to_pstring
    test_string     = "test"
    expected_string = "\004test"
    
    buffer  = test_string.to_pstring
    
    assert_equal expected_string, buffer, "The buffer has a null character at the end"
    assert_equal "\004", buffer[0,1],     "The first character in the buffer is a length byte"
    assert_equal 4, test_string.length,   "length of test_string remains unchanged"
    assert_equal 5, buffer.length,        "length of buffer is 1 greater than test_string"

    assert_equal 'String', buffer.class.to_s, "class is String"
    
  end


  ###############################################################
  def test_from_pstring
    
    test_string     = "\004test"    # The last character of a cstring is a null character
    expected_string = "test"
    
    thing1  = test_string.from_pstring
    
    assert_equal 'String', thing1.class.to_s, "class is String"
    assert_equal expected_string, thing1,     "unpacked value is the same as the packed value"
    
    assert_equal 4, thing1.length
        
  end


  ###############################################################
  def test_to_p2string
    test_string     = "test"
    expected_string = "\000\004test"
    
    buffer  = test_string.to_p2string
    
    assert_equal expected_string, buffer, "The buffer has 2 bytes of length data in from of the string value"
    assert_equal 4, test_string.length,   "length of test_string remains unchanged"
    assert_equal 6, buffer.length,        "length of buffer is 2 greater than test_string"
    
    assert_equal 'String', buffer.class.to_s, "class is String"
    
  end


  ###############################################################
  def test_from_p2string
    
    test_string     = "\000\004test"
    expected_string = "test"
    
    thing1  = test_string.from_p2string
    
    assert_equal 'String', thing1.class.to_s, "class is String"
    
    assert_equal expected_string, thing1,     "unpacked value is the same as the packed value"
    
  end



  ###############################################################
  def test_to_p4string
    test_string     = "test"
    expected_string = "\000\000\000\004test"
    
    buffer  = test_string.to_p4string
    
    assert_equal expected_string, buffer, "The buffer has 4 bytes of length value prepend to the string"
    assert_equal 4, test_string.length,   "length of test_string remains unchanged"
    assert_equal 8, buffer.length,        "length of buffer is 4 greater than test_string"

    assert_equal 'String', buffer.class.to_s, "class is String"
    
  end


  ###############################################################
  def test_from_p4string
    
    test_string     = "\000\000\000\004test"
    expected_string = "test"
    
    thing1  = test_string.from_p4string
    
    assert_equal 'String', thing1.class.to_s, "class is String"
    
    assert_equal expected_string, thing1,     "unpacked value is the same as the packed value"
    
  end


end ## end of class TestStringMods < Test::Unit::TestCase

