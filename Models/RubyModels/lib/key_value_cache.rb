#################################################################
###
##  File: key_value_cache.rb
##  Desc: Establishes a class to access common key value stores
##
##  NOTE: This is __NOT__ a cache in the sense that is supported by ActiveReocrd.
##        Rather it is a generic wrapper around key-value stores.
#

# KeyValueCache is a consistent wrapper class around various key/value stores
# The initial implementation uses the LocalMemCache gem
#
# kvc=KeyValueCache.new           #=> starts up a local memory cache with default options
# kvc=KeyValueCache.new :local    #=> starts up a local memory cache with default options
# kvc=KeyValueCache.new :local, :option_name=>option_value, etc.
#                   #=> options are:
#                        :namespace, :size_mb, :min_alloc_size, :root
#                         (see code for definitions and defaults)
#
# KeyValueCache.new :database #=> TODO: uses a database table
#
# KeyValueCache.new :network  #=> TODO: uses a network-based key/value store like memcache, resque
#
# Common accesser/getter functions are:
#   kvc.get a_key
#   kvc.set a_key, a_value
#   kvc[a_key]
#   kvc[a_key] = a_value
#

class KeyValueCache

  attr_reader :kvc
  attr_reader :options

  def initialize(handler = :local, my_options={})

    case handler

    when :local then

      default_options = { 
        :namespace      => 'KeyValue',    # name of the sparse file (ext is *.lmc)
        :size_mb        => 7,             # maximum size of the memory block in mega bytes
        :min_alloc_size => 1024,          # minimum allication size in kilo bytes
        :root           => ENV['HOME'] + '/tmp'}  # root directory of the sparse mmap()'ed file

      @options = default_options.merge(my_options)

      # default: /var/tmp/localmemcache
      ENV['LMC_NAMESPACES_ROOT_PATH'] = @options[:root]

      # @options.delete(:root)

      require 'localmemcache'

      @kvc = LocalMemCache::SharedObjectStorage.new(@options)

    when :network then

      # TODO: Implement other key/value stores like memcache, resque, etc.

      raise "NotImplementedYet #{handler} cache handler"

    when :database then

      # TODO: Implement access to database table implementation of a key/value store

      raise "NotImplementedYet #{handler} cache handler"

    else

      raise "#{handler} is not defined as a cache handler"

    end ## end of case cache_handler

  end ## end def initialize(handler = :local, options={})


  ###################################################
  ## Using method_missing to handle uncommon methods.
  ## Invocation of method_missing means that Ruby has
  ## search the entire hierarchical class stack looking
  ## for a way to satistify this method call and it was
  ## not found.
  def method_missing(sym, *args, &block)

    mm_name = sym.id2name   # convert the symbol ID into an actual method name

    # Complain if the underlying KV store can not handle the method
    raise NoMethodError unless @kvc.respond_to?(mm_name)

    # Define this missing method as a new instance method
    instance_eval <<-EOS
      def #{mm_name}(*args, &block)
        @kvc.send :#{mm_name}, *args, &block
      end
    EOS

    # Provide the answer the first time, subsequent calls
    # will be handled by the newly created method
    @kvc.send sym, *args, &block

  end

  #################################################
  ## Common functions used by most key/value stores
  ## Not some common functions will be dynamically created
  ## by the method_missing method aboce.
  def [](a_key)
    @kvc.get(a_key)
  end

  def []=(a_key, a_value)
    @kvc.set(a_key, a_value)
  end

  alias get []
  alias set []=

end ## end of class KeyValueCache

