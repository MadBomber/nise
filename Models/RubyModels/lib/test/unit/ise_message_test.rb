#!/usr/bin/env ruby
#####################################################################
###
##  File:  test_ise_message.rb
##  Desc:  IseMessage is the base class for all ISE messages touched by Ruby
##         This unit test is primarily for testing the new features.  A functional
##         test program may still reside in $ISE_ROOT/Webapp/Portal
#

require 'IseMessage'

require 'pp'
require 'string_mods'

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

#################################################################
## The test message used in the tests below
class TestMessage < IseMessage
  def initialize
    super
    desc "A Test Message"
    item(:cstring,  :tm_cstring1_)    # An ISE cpmvemtion is to use a trailing underscore on message components
    item(:cstring,  :tm_cstring2_)
    item(:pstring,  :tm_pstring1_)
    item(:pstring,  :tm_pstring2_)
    item(:INT16,    :tm_int16_)       # FIXME: :int16 gives an error, need to fix format_code to be consistent
                                      #        The syntax of the format codes was developed to match the
                                      #        requirement of the types used in C++
  end
end

#################################################################
## Test case of basic functionality of the IseMessage class
class TestIseMessage < Test::Unit::TestCase

  #################################################################
  ## setup a known TestMessage for each unit test
  def setup
  
    @tm = TestMessage.new
    
    @number_of_items = 5
    
    @tm.tm_cstring1_ = "Dewayne"   # length: 8 bytes = 7 characters + 1 null
    @tm.tm_cstring2_ = "Ella"      # length: 5
    @tm.tm_pstring1_ = "Diane"     # length: 6 bytes = 1 length byte + 5 characters
    @tm.tm_pstring2_ = "Janet"     # length: 6
    @tm.tm_int16_    = 12345       # length: 2 bytes 16-bit signed integer
                                   # TOTAL: 27 bytes
    @total_msg_length = 27 # bytes

                           # D e w a y n e   E l l a     D i a n e   J a n e t
    @expected_out_as_hex  = "44657761796e6500456c6c6100054469616e65054a616e65743039"
    
  end

  #################################################################
  ## Test the basic structure to ensure understanding of what is in
  ## an IseMessage instance
  def test_new

    # test ckasses
    assert_equal 'TestMessage', @tm.class.to_s, "it is a TestMessage"
    assert_equal 'String',      @tm.tm_cstring1_.class.to_s
    assert_equal 'String',      @tm.tm_cstring2_.class.to_s
    assert_equal 'String',      @tm.tm_pstring1_.class.to_s
    assert_equal 'String',      @tm.tm_pstring2_.class.to_s
    assert_equal 'Fixnum',      @tm.tm_int16_.class.to_s
    
    # test values
    assert_equal 'Dewayne',     @tm.tm_cstring1_
    assert_equal 'Ella',        @tm.tm_cstring2_
    assert_equal 'Diane',       @tm.tm_pstring1_
    assert_equal 'Janet',       @tm.tm_pstring2_
    assert_equal 12345,         @tm.tm_int16_
    
    # test buffers
    assert_equal "",            @tm.out
    assert_equal "",            @tm.raw
    assert_equal "",            @tm.xml
    assert                      @tm.hash.empty?
    
    # test utility items
    assert_equal 6,                     @tm.max_size        # FIXME: max_size is deprecated
    assert_equal 0,                     @tm.msg_flag_mask_
    assert_equal 'Array',               @tm.msg_items.class.to_s
    assert_equal @number_of_items,      @tm.msg_items.length
    assert_equal 2,                     @tm.msg_items[0].length
    assert_equal :tm_cstring1_,         @tm.msg_items[0][0]
    assert_equal :cstring,              @tm.msg_items[0][1]
    assert_equal [:tm_int16_, :INT16],  @tm.msg_items.last
    
  end


  #################################################################
  def test_to_h
    a_hash = @tm.to_h
    assert_equal @tm.hash,          a_hash
    assert_equal @number_of_items,  a_hash.length
    
    @tm.msg_items.each do |an_item|
      assert a_hash.include?(an_item[0]), "#{an_item[0]} should be in the hash"
    end
    
    assert_equal 'String',      a_hash[:tm_cstring1_].class.to_s
    assert_equal 'String',      a_hash[:tm_cstring2_].class.to_s
    assert_equal 'String',      a_hash[:tm_pstring1_].class.to_s
    assert_equal 'String',      a_hash[:tm_pstring2_].class.to_s
    assert_equal 'Fixnum',      a_hash[:tm_int16_].class.to_s
    
    assert_equal 'Dewayne',     a_hash[:tm_cstring1_]
    assert_equal 'Ella',        a_hash[:tm_cstring2_]
    assert_equal 'Diane',       a_hash[:tm_pstring1_]
    assert_equal 'Janet',       a_hash[:tm_pstring2_]
    assert_equal 12345,         a_hash[:tm_int16_]
    
  end

  #################################################################
  def test_pack_message_as_binary

    buffer = @tm.pack_message

    assert_equal buffer,            @tm.out, "method return should be the same as the @out buffer"    
    assert_equal @total_msg_length, @tm.out.length, "length of out string is expected msg length"

    buffer_as_hex = buffer.to_hex
    
    assert_equal @expected_out_as_hex, buffer_as_hex, "got to be the right message"

  end

  #################################################################
  def test_unpack_message_as_binary

    buffer      = @tm.pack_message
    new_tm      = TestMessage.new
    new_tm.raw  = buffer
    
    new_tm.unpack_message
    
    assert_equal 'Dewayne',     new_tm.tm_cstring1_
    assert_equal 'Ella',        new_tm.tm_cstring2_
    assert_equal 'Diane',       new_tm.tm_pstring1_
    assert_equal 'Janet',       new_tm.tm_pstring2_
    assert_equal 12345,         new_tm.tm_int16_

  end


=begin
  def test_class_hex_dump
    raise NotImplementedError, 'Need to write test_class_hex_dump'
  end

  def test_class_inherited
    raise NotImplementedError, 'Need to write test_class_inherited'
  end

  def test_class_sub_classes
    raise NotImplementedError, 'Need to write test_class_sub_classes'
  end

  def test_class_subscribe
    raise NotImplementedError, 'Need to write test_class_subscribe'
  end

  def test_class_unsubscribe
    raise NotImplementedError, 'Need to write test_class_unsubscribe'
  end

  def test_app_message
    raise NotImplementedError, 'Need to write test_app_message'
  end

  def test_app_message_equals
    raise NotImplementedError, 'Need to write test_app_message_equals'
  end

  def test_desc
    raise NotImplementedError, 'Need to write test_desc'
  end

  def test_desc_equals
    raise NotImplementedError, 'Need to write test_desc_equals'
  end

  def test_dest_id_
    raise NotImplementedError, 'Need to write test_dest_id_'
  end

  def test_dest_id__equals
    raise NotImplementedError, 'Need to write test_dest_id__equals'
  end

  def test_explode_items
    raise NotImplementedError, 'Need to write test_explode_items'
  end

  def test_format_code
    raise NotImplementedError, 'Need to write test_format_code'
  end

  def test_from_xml
    raise NotImplementedError, 'Need to write test_from_xml'
  end

  def test_hash_equals
    raise NotImplementedError, 'Need to write test_hash_equals'
  end

  def test_item
    raise NotImplementedError, 'Need to write test_item'
  end

  def test_max_size
    raise NotImplementedError, 'Need to write test_max_size'
  end

  def test_max_size_equals
    raise NotImplementedError, 'Need to write test_max_size_equals'
  end

  def test_msg_flag_mask_
    raise NotImplementedError, 'Need to write test_msg_flag_mask_'
  end

  def test_msg_flag_mask__equals
    raise NotImplementedError, 'Need to write test_msg_flag_mask__equals'
  end

  def test_msg_items
    raise NotImplementedError, 'Need to write test_msg_items'
  end

  def test_msg_items_equals
    raise NotImplementedError, 'Need to write test_msg_items_equals'
  end

  def test_out
    raise NotImplementedError, 'Need to write test_out'
  end

  def test_out_equals
    raise NotImplementedError, 'Need to write test_out_equals'
  end

  def test_pos
    raise NotImplementedError, 'Need to write test_pos'
  end

  def test_pos_equals
    raise NotImplementedError, 'Need to write test_pos_equals'
  end

  def test_publish
    raise NotImplementedError, 'Need to write test_publish'
  end

  def test_raw
    raise NotImplementedError, 'Need to write test_raw'
  end

  def test_raw_equals
    raise NotImplementedError, 'Need to write test_raw_equals'
  end

  def test_register
    raise NotImplementedError, 'Need to write test_register'
  end

  def test_to_xml
    raise NotImplementedError, 'Need to write test_to_xml'
  end

  def test_xml
    raise NotImplementedError, 'Need to write test_xml'
  end

  def test_xml_equals
    raise NotImplementedError, 'Need to write test_xml_equals'
  end
=end

end ## end of class TestIseMessage < Test::Unit::TestCase

