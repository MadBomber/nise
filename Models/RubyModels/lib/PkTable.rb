##############################################################
###
##  File:  PkTable.rb
##  Desc:  Probability of Kill Table
##         Uses a modified bilinear interpolation
##
## TODO: encapsulate the PkTable class within a Pk module
##       Move the load_pk_tables method from aadse_utilities to
##       the new module.

require 'rubygems'
require 'pathname'
require 'debug_me'

class PkTable
  
  attr_accessor :range_scale
  attr_accessor :altitude_scale
  attr_reader :scale_units
  attr_reader :range_max
  attr_reader :altitude_max
  attr_reader :pk_pathname
  attr_reader :pk
  attr_reader :expected_row_size
  attr_reader :expected_column_size
  attr_reader :expected_range_max
  attr_reader :expected_altitude_max
  
  ###############################
  def initialize(pk_filename=nil)
    @pk = Array.new
    
    if pk_filename.nil?
      @range_max      = 30000.0
      @altitude_max   = 30000.0
      @range_scale    = 10000.0
      @altitude_scale = 10000.0
      @pk = [ [0,45,75,0],
              [0,75,95,0],
              [0,45,75,0],
              [0,0,0,0]  ]
      @pk_pathname = nil
    else
      if 'Pathname' == pk_filename.class.to_s
        @pk_pathname = pk_filename.realpath
      else
        @pk_pathname = Pathname.new pk_filename
      end
      raise "File Does Not Exist: #{@pk_pathname}" unless @pk_pathname.exist?
      @pk_pathname.each_line do |a_line|
        al = a_line.chomp.strip.gsub(' ','').downcase
        next if al.empty? or '#' == al[0,1]
        al_array = al.split(',')
        if 'scale' == al_array[0].downcase
          @range_scale    = al_array[1].to_f
          @altitude_scale = al_array[2].to_f
          @scale_units    = al_array[3]
        elsif 'size'  == al_array[0].downcase
          @expected_row_size    = al_array[1].to_f
          @expected_column_size = al_array[2].to_f
        elsif 'max'  == al_array[0].downcase
          @expected_range_max    = al_array[1].to_f
          @expected_altitude_max = al_array[2].to_f
        else
          al_array << 0     # add altitude buffer for bilinear inter use later
          @pk << al_array
        end
      end
      range_index_max     = @pk.length
      altitude_index_max  = @pk[0].length - 1
      @range_max          = range_index_max * @range_scale
      @altitude_max       = altitude_index_max * @altitude_scale
      @pk.each_index do |range_index|
        @pk[range_index].each_index do |altitude_index|
          @pk[range_index][altitude_index] = @pk[range_index][altitude_index].to_i
        end
      end
      @pk[range_index_max] = []
      (altitude_index_max+1).times do |x|
        @pk[range_index_max] << 0
      end
    end
    
    $debug_pk = false unless defined?($debug_pk)
    
    puts "PkTable Loaded -=>  File: #{@pk_pathname}   Range Max: #{@range_max}    Alt. Max: #{@altitude_max}" if $verbose
    
  end   ## end of def initialize(pk_filename=nil)
  
  #######################################
  def at(range=30000.0, altitude=30000.0)
    
    debug_me("PK-AT-PARAMS"){[:range, :altitude]} if $debug_pk
    

    if (range > @range_max)  or (altitude > @altitude_max)
      debug_me("PK-RANGE-OR-ALT-BEYOUND-MAX"){[:@range_max, :@altitude_max]} if $debug_pk
      return 0.0
    end

    if (range < 0)           or (altitude < 0)
      debug_me("PK-RANGE-OR-ALT-NEGATIVE") if $debug_pk
      return 0.0
    end
    
    range_index         = Integer(range / @range_scale)
    altitude_index      = Integer(altitude / @altitude_scale)


    if (range_index >= @expected_row_size) or (altitude_index >= @expected_column_size)
      debug_me("PK-INDEX-BEYOUND-EDGE"){[:@expected_row_size, :@expected_column_size, :range_index, :altitude_index]} if $debug_pk
      return 0.0 
    end
       
      debug_me("PK-INDEX"){[:range_index, :altitude_index]} if $debug_pk
    
    a = @pk[range_index][altitude_index]
    b = @pk[range_index][altitude_index+1]
    c = @pk[range_index+1][altitude_index]
    d = @pk[range_index+1][altitude_index+1]
    
    
    delta_ac = a - c
    delta_bd = b - d

    debug_me("PK-VALUES"){[:a, :b, :c, :d, :delta_ac, :delta_bd]} if $debug_pk

    delta_range = (range_index * range_scale) - range
    delta_altitude = (altitude_index * altitude_scale) - altitude
    
    debug_me("PK-DELTAS"){[:delta_range, :delta_altitude]} if $debug_pk
    
    range_factor = delta_range / range_scale
    altitude_factor = delta_altitude / altitude_scale
    
    debug_me("PK-FACTORS"){[:range_factor, :altitude_factor]} if $debug_pk
    
    pk1 = a + delta_ac * range_factor
    pk2 = b + delta_ac * range_factor
    
    delta_altitude = pk1 - pk2

    debug_me("PK-INTER-PRODUCT-DELTA"){[:pk1, :pk2, :delta_altitude]} if $debug_pk


    pk = pk1 + delta_altitude * altitude_factor
    
    debug_me("PK-FINAL"){[:pk, :pk1, :delta_altitude, :altitude_factor]} if $debug_pk
    
    return pk
    
  end ## end of def at(range=30000.0, altitude=30000.0)
  
  
  ########################################################
  def to_s
    a_str = ""
    a_str << "filepath: #{@filepath}\n"
    a_str << "  platform:       #{@platform}\n"
    a_str << "  tgt_type:       #{@tgt_type}\n"
    a_str << "  range_max:      #{@range_max}\n"
    a_str << "  altitude_max:   #{@altitude_max}\n"
    a_str << "  range_scale:    #{@range_scale}\n"
    a_str << "  altitude_scale: #{@altitude_scale}\n"
    a_str << "  Pk Array:       #{@pk}\n"
    return a_str
  end
  
end ## end of class PkTable
