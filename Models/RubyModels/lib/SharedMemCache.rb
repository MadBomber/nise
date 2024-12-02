################################################################
###
##  File: SharedMemCache.rb
##  Desc: Use memcached for pseudo shared memory
##
##  To make use of this class to auto save to the memcache a source
##  class must include the Observable pattern.  The method 'changed'
##  must be called to indicate that attributes within the class have
##  if fact, changed.  Finally the source class must call the notify_observers
##  method.  See the class StatsCollector as an example.
#

require 'SafeMemCache'

class SharedMemCache

  @@smc         = nil
  @@KEY         = 'SMC:data'  ## the @@data and associated @@KEY implement a simple
  @@data        = nil         ## Data Dictionary system to document the contents of the cache
  @@key_len_max = 40          ## maximum allowed length of a key

  def initialize(some_observable_class_instance=nil, mc_server=nil, mc_options={:no_reply => true})
  
    if mc_server.nil?
      mc_ip     = ENV['MC_IP']  || "138.209.52.147"
      mc_port   = ENV['MC_PORT'] || "11211"
    else
      mc_array  = mc_server.split(':')
      mc_ip     = mc_array[0]
      mc_port   = mc_array[1]
    end
  
    @@smc = SafeMemCache.new("#{mc_ip}:#{mc_port}", mc_options) if @@smc.nil?
    
    some_observable_class_instance.add_observer(self) if some_observable_class_instance
    
    unless @@data
      @@data = @@smc.get(@@KEY)
      unless @@data
        @@data          = Hash.new
        @@data[@@KEY]   = "The Data Dictionary for the Shared Mem Cache"
        @@smc.set(@@KEY, @@data)
      end
    end
  
  end ## end of def initialize
  
  ###################################
  ## Called by the Observable Pattern
  
  def update(key, value)
    @@smc.set(key.to_s, value)
  end



  ##################################
  ## Use with caution!
  def self.flush_all_data_from_all_caches
    @@smc.flush_all
    @@data = {}
  end



  ########################
  def self.set(key, value)
    rv = @@smc.set(key.to_s, value)
    unless @@data.include?(key.to_s)
      $stderr.puts "WARNING: set #{key.to_s} but it is not in the data dictionary."
      self.add(key, "Undefined Instance of Class #{value.class}")
    end
  end
  
  #################
  def self.get(key)
    thing = @@smc.get(key.to_s)
    $stderr.puts "DEBUG: GET #{key.to_s} to class: #{thing.class}" if $debug_smc
    return thing
  end

  
  #################
  def self.delete(key)
    thing = @@smc.delete(key.to_s)
    @@data.delete key
    $stderr.puts "DEBUG: DELETE #{key.to_s}" if $debug_smc
    return thing
  end
  
  #################
  def self.stats
    thing = @@smc.stats
    $stderr.puts "DEBUG: STATS" if $debug_smc
    return thing
  end
  
  
  ##############################
  def self.add(key, description)
    unless @@data.include? key
      raise "SharedMemCache#add key length: #{key.length}  exceeds limit: #{@@key_len_max}" if key.length > @@key_len_max
      @@data[key.to_s] = description
      @@smc.set(@@KEY, @@data)    
      $stderr.puts "DEBUG: added #{key.to_s}  Description: #{description}" if $debug_smc
    end
  end

  
  #######################
  def self.what_is(thing)
    @@data[thing.to_s]
  end

  
  #############
  def self.data
    @@data
  end
  
  
  ######################
  def self.data=(a_hash)
    if 'Hash' == a_hash.class.to_s
      @@data = a_hash
      @@smc.set(@@KEY, @@data)
    else
      $stderr.puts "\nERROR: SharedMemCache#data= has bad class for parameter: #{a_hash.class}\n"
    end
  end


  
end ## end of class SharedMemCache

