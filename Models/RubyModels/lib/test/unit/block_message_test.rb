#!/usr/bin/env ruby
#####################################################################
###
##  File:  test_block_message.rb
##  Desc:  Unit tests for the BlockMessage class

require 'rubygems'
require 'pp'

require 'BlockMessage'
require 'string_mods'

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

#################################################################
## The test message used in the tests below
class TestBlockMessage < BlockMessage
  def initialize(a_string="")
    super
    desc "A Test Message"
  end
end

#################################################################
## Test case of basic functionality of the IseMessage class
class TestIseMessage < Test::Unit::TestCase

  #################################################################
  ## setup a known TestMessage for each unit test
  def setup
    
    @known_string     = "When in the course of program events it becomes necessary to send a block of unstructured data, use the BlockMessage class."
    @total_msg_length = @known_string.length
    
    @tm               = TestBlockMessage.new @known_string
        
  end

  #################################################################
  ## Test the basic structure to ensure understanding of what is in
  ## an IseMessage instance
  def test_new

    assert_equal @known_string, @tm.data
    assert_equal @known_string, @tm.out
    assert_equal @known_string, @tm.raw

  end

  def test_new_2

    a_tm = TestBlockMessage.new
    a_tm.data = @known_string
    
    assert_equal @known_string, a_tm.data
    assert_equal @known_string, a_tm.out
    assert_equal @known_string, a_tm.raw

  end

  def test_new_3

    begin
      a_tm = TestBlockMessage.new({:anything => "This is NOT a String"})
      assert false, "Expected an exception to be generated"
    rescue
      assert true, "Got the exception"
    end
    
  end



  #################################################################
  def test_to_h
  
    a_hash = @tm.to_h
    
    assert_equal 'Hash', a_hash.class.to_s,   "a hash is a Hash"
    assert_equal 1, a_hash.length,            "There is only 1 element in this Hash"
    
    assert a_hash.include?(:data),            ":data is a key in the Hash"
    assert_equal a_hash,        @tm.hash,     "The internal hash is the same as the external hash"
    assert_equal @known_string, a_hash[:data],"the value of the :data element of the has is as expected"
    
  end

  #################################################################
  def test_msg_items
    assert_equal 'Array',         @tm.msg_items.class.to_s
    assert_equal 1,               @tm.msg_items.length
    assert_equal [:data, :string],@tm.msg_items[0]
  end

  #################################################################
  def test_item
    begin
      @tm.item(:cstring, :silly_name_)
      assert false, "wanted an exception, did not get it"
    rescue
      assert true, "exception was expected"
    end
  end

  #################################################################
  def test_pack_message_as_binary

    buffer = @tm.pack_message

    assert_equal buffer,            @tm.out, "method return should be the same as the @out buffer"    
    assert_equal @total_msg_length, @tm.out.length, "length of out string is expected msg length"

    assert_equal @known_string, buffer

  end

  #################################################################
  def test_unpack_message_as_binary

    buffer      = @tm.pack_message
    new_tm      = TestBlockMessage.new
    new_tm.raw  = buffer
    
    new_tm.unpack_message
    
    assert_equal @known_string, new_tm.data
    assert_equal @known_string, new_tm.out
    assert_equal @known_string, new_tm.raw

  end

end ## end of class TestIseMessage < Test::Unit::TestCase

