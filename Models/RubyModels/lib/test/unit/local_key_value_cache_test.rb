#!/usr/bin/env ruby
#################################################################
###
##  File: test_key_value_cache.rb
##  Desc: Unit test for the KeyValueCache
##
##  NOTE: This is __NOT__ a cache in the sense that is supported by ActiveReocrd.
##        Rather it is a generic wrapper around key-value stores.
#

require 'key_value_cache'   # system under test

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

class TestLocalKeyValueCache < Test::Unit::TestCase

  ##############################################################
  def setup
    @sm = KeyValueCache.new( :local, :namespace => 'UnitTest' )
    @before_methods = @sm.methods
    @sm[:one]   = 1
    @sm[:two]   = 2
    @sm[:three] = 3
    @sm[:four]  = 4
    @sm[:five]  = 5
    @sm.delete(:six)
    @after_methods = @sm.methods
  end
  
  ##############################################################
  def test000_initialize_default_options
    File.exists?(ENV['HOME'] + '/tmp/UnitTest.lms')
  end

  ##############################################################
  def test_get
    assert_equal 5, @sm.keys.length
    assert_equal 1, @sm.get(:one)
    assert_equal 2, @sm.get(:two)
    assert_equal 3, @sm.get(:three)
    assert_equal 4, @sm.get(:four)
    assert_equal 5, @sm.get(:five)
  end

  ##############################################################
  def test_method_missing
    # NOTE: symboles are stored as strings
    assert_equal ["delete"], @after_methods - @before_methods
  end

  ##############################################################
  def test_set
    assert_equal false, @sm.keys.include?(:six)
    @sm[:six] = 6
    assert @sm.keys.include?('six')
    assert_equal false, @sm.keys.include?(:six)
    assert_equal 6, @sm[:six]
    assert_equal 6, @sm.get(:six)
    assert_equal 6, @sm['six']
  end

  ##############################################################
  def test_kvc
    assert_equal 'LocalMemCache::SharedObjectStorage', @sm.kvc.class.to_s
  end

  ##############################################################
  def test_options
    assert_equal 4, @sm.options.length
    
    assert @sm.options.include? :namespace      # name of the sparse file (ext is *.lmc)
    assert @sm.options.include? :size_mb        # maximum size of the memory block in mega bytes
    assert @sm.options.include? :min_alloc_size # minimum allication size in kilo bytes
    assert @sm.options.include? :root           # root directory of the sparse mmap()'ed file
    
    assert_equal 'UnitTest', @sm.options[:namespace]       # name of the sparse file (ext is *.lmc)
    assert_equal 7, @sm.options[:size_mb]                  # maximum size of the memory block in mega bytes
    assert_equal 1024, @sm.options[:min_alloc_size]        # minimum allication size in kilo bytes
    assert_equal ENV['HOME'] + '/tmp', @sm.options[:root]  # root directory of the sparse mmap()'ed file
  end

  ##############################################################
  def test_index
    assert_equal 1, @sm[:one]
    assert_equal 2, @sm[:two]
    assert_equal 3, @sm[:three]
    assert_equal 4, @sm[:four]
    assert_equal 5, @sm[:five]
    
    assert_equal 1, @sm['one']
    assert_equal 2, @sm['two']
    assert_equal 3, @sm['three']
    assert_equal 4, @sm['four']
    assert_equal 5, @sm['five']
  end

  ##############################################################
  def test_index_equals
    assert_equal false, @sm.keys.include?(:six)
    @sm[:six] = 6
    assert @sm.keys.include?('six')
    assert_equal false, @sm.keys.include?(:six)
    assert_equal 6, @sm[:six]
    assert_equal 6, @sm['six']
  end
  
  ##############################################################
  def test_keys
    array_of_keys = @sm.keys
    assert_equal 'Array', array_of_keys.class.to_s
    
    assert_equal 5, array_of_keys.length
    
    assert array_of_keys.include?('one')
    assert array_of_keys.include?('two')
    assert array_of_keys.include?('three')
    assert array_of_keys.include?('four')
    assert array_of_keys.include?('five')
  end
  
end ## end of class TestLocalKeyValueCache < Test::Unit::TestCase

