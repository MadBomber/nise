##################################################################
###
##  File:  SimTime.rb
##  Desc:  should be funcitonally the same as TimeStamp.pm
##
#

require 'time'
require 'time_mods'
require 'observer'

class SimTime

  include Observable

  attr_accessor :start_time
  attr_accessor :end_time
  attr_reader   :sim_time
  attr_reader   :offset         ## typically sim_time minus start_time
  attr_accessor :step_seconds
  attr_accessor :stk_is_time_lord   ## when true means that STK is the master time keeper.
  attr_accessor :duration           ## duration in seconds of the sim (end_time - start_time)

  #alias :now :sim_time


  ##############
  def initialize( decimal_seconds=1.0,
    start_time_str='1 Jul 2005 12:00:00.000',   ## 6/3/53 would be better!
    end_time_str='2 Jul 2005 12:00:00.000',
    stk_is_time_lord=false)

    @step_seconds     = decimal_seconds
    
    if 'String' == start_time_str.class.to_s
      @start_time       = Time.parse start_time_str
      @end_time         = Time.parse end_time_str
    else
      @start_time       = start_time_str
      @end_time         = end_time_str
    end
    
    @sim_time         = @start_time
    @offset           = 0.0
    @duration         = @end_time - @start_time
    @stk_is_time_lord = false
    
#    @stk_is_time_lord = stk_is_time_lord

  end ## end of def initialize

  #####################
  def now
    return @offset
  end
  
  ####################
  def time_left
    return @duration - @offset
  end
  
  #####################
  def sim_time=(a_time)
    case a_time.class.to_s
      when 'Time' then
        @sim_time = a_time
      when 'String' then
        @sim_time = Time.parse a_time
      else
        $stderr.puts "ERROR: Invalid sim_time assignment: #{a_time}"
    end
    
    @sim_time = @start_time if @sim_time < @start_time
    @sim_time = @end_time   if @sim_time > @end_time
    
    @offset   = @sim_time - @start_time
    
    changed
    notify_observers('sim_time', @sim_time)
    
  end
  

  #########
  def reset

    @sim_time = @start_time
    @offset   = 0.0

    changed
    notify_observers('sim_time', @sim_time)

  end ## end of def Reset


  #########
  def offset=(an_offset)

    @sim_time = @start_time + an_offset
    @offset   = an_offset

    changed
    notify_observers('sim_time', @sim_time)

  end ## end of def Reset



  #############
  def advance_time
    unless @stk_is_time_lord
      @sim_time += @step_seconds
      @offset   += @step_seconds
    end

    changed
    notify_observers('sim_time', @sim_time)

  end ## end of def advance_time



  #############
  def reverse_time
    unless @stk_is_time_lord
      @sim_time -= @step_seconds
      @offset   -= @step_seconds
    end

    changed
    notify_observers('sim_time', @sim_time)

  end ## end of def Decrement



  #########
  def to_s

    return sprintf('%s%06.3f', @sim_time.strftime("%d %b %Y %H:%M:"), @sim_time.sec)

  end ## end of def print_with_double_quotes


  ##########
  def stkfmt
    return @sim_time.stkfmt
  end

  #######
  def end_of_sim?

    return @sim_time >= @end_time

  end ## end of def End


  alias :print_with_double_quotes :stkfmt

end ## end of class SimTime


################################################
=begin

Format meaning for strftime:

  %a - The abbreviated weekday name (``Sun'')
  %A - The  full  weekday  name (``Sunday'')
  %b - The abbreviated month name (``Jan'')
  %B - The  full  month  name (``January'')
  %c - The preferred local date and time representation
  %d - Day of the month (01..31)
  %H - Hour of the day, 24-hour clock (00..23)
  %I - Hour of the day, 12-hour clock (01..12)
  %j - Day of the year (001..366)
  %m - Month of the year (01..12)
  %M - Minute of the hour (00..59)
  %p - Meridian indicator (``AM''  or  ``PM'')
  %S - Second of the minute (00..60)
  %U - Week  number  of the current year,
          starting with the first Sunday as the first
          day of the first week (00..53)
  %W - Week  number  of the current year,
          starting with the first Monday as the first
          day of the first week (00..53)
  %w - Day of the week (Sunday is 0, 0..6)
  %x - Preferred representation for the date alone, no time
  %X - Preferred representation for the time alone, no date
  %y - Year without a century (00..99)
  %Y - Year with century
  %Z - Time zone name
  %% - Literal ``%'' character

   t = Time.now
   t.strftime("Printed on %m/%d/%Y")   #=> "Printed on 04/09/2003"
   t.strftime("at %I:%M%p")            #=> "at 08:56AM"

=end

