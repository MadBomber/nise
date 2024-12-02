#################################################################
###
##  File: EphemerisArray.rb
##  Desc: The EphemerisArray provides utility functions to process 4D positional data
#

class EphemerisArray

  attr_accessor :data         # The Array used to initialize this class instances
  attr_accessor :curr_index   # The current index (represents current time)
  attr_accessor :next_index   # The next index to access in this data array; assumes liner time
  attr_accessor :last_index   # The length of the data array minus one

  class BeyondLastIndex < Exception; end

  def initialize(an_array=[])

    throw :ParameterIsNotAnArray unless 'Array' == an_array.class.to_s
#    throw :ArrayIsEmpty if an_array.empty?

    an_array.length.times do |row|
      throw :ArrayIsNot4D unless 4 == an_array[row].length
      4.times do |col|
        throw :ArrayIsNotAllFloat unless 'Float' == an_array[row][col].class.to_s
      end
    end

    # have a 4D array; assuming its t, x, y, z
    # all elements are of type Float
    # don't care about the units so long as t is in order

    @data       = an_array
    @curr_index = nil
    @next_index = 0
    @last_index = an_array.length - 1

  end

  ########
  def now
    return nil if @curr_index.nil?
    return @data[@curr_index]
  end

  ########
  def succ
    raise BeyondLastIndex if @next_index > @last_index
    a = @data[@next_index]
    @curr_index = @next_index
    @next_index += 1
    return a
  end

  ########
  def prev
    @curr_index = @next_index     # SMELL: don't think this is right
    @next_index -= 1 if 0 < @next_index
    a = @data[next_index]
    return a
  end

  #################
  def add(an_array=nil)
    throw :ParameterIsNotAnArray unless 'Array' == an_array.class.to_s
    throw :ArrayIsEmpty if an_array.empty?
    
    # normalize to a 2D array
    
    unless 'Array' == an_array[0].class.to_s
      an_array = [an_array]
    end
    
    # test each row
    
    an_array.each do |aa|
      throw :ArrayIsNot4D unless 4 == aa.length
      4.times do |x|
        throw :ArrayIsNotAllFloat unless 'Float' == aa[x].class.to_s
      end
    end
    
    # an_array is well formatted
    
    an_array.each do |aa|
      @data << aa
    end
    
    @last_index += an_array.length
  end
  

  ###################
  def get(a_time=nil)
    throw :ParameterIsNotFloat unless 'Float' == a_time.class.to_s
    throw :ParameterInThePast unless a_time >= @data[@curr_index?@curr_index:@next_index][0]

    @curr_index = @next_index unless @curr_index

    #    debug
    #    puts a_time

    begin
      while (a_time > @data[@next_index][0]) do
        b = succ
      end
    rescue
      return now
    end

    #    b = @data[@curr_index]
    a = @data[@next_index]

    ###########################################
    # Linear interpolation based on time where:
    # b=before, a=after, t=time, d=delta, o=offset, r=ratio, n=new
    # FIXME: assumes positional data elements increase; possible that they could decrease while time always increases

    tb=b[0]; ta=a[0]; dt=ta-tb; ot=a_time - tb; tr = ot / dt

    n = b.dup
    n[0] = a_time

    # adjust each positional coordinate by the same ratio
    (1..3).each do |xyz|
      delta = a[xyz] - b[xyz]
      n[xyz] += tr * delta
    end

    return n  # for testing the test procedures
  end


  def debug
    puts
    labels = ["curr", "next", "last"]
    values = [@curr_index, @next_index, @last_index]
    3.times do |x|
      z = values[x]
      puts "DEBUG: #{labels[x]}[#{z}] -=> #{@data[z].join(', ')}"
    end
  end

end ## of class EphemerisArray < Array

