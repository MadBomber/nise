#########################################################################
###
##  Global definitions for ISE Scenario DSL
##
##  IseScenario defines the Domain Specific Language (DSL) used to
##  drive simulations.

class IseScenario

  @@kids = []           ## an array to hold pointers to instances of class
  @@messages = {}       ## a hash to hold received messages

  @@events          = Hash.new    ## event-based tasks
  @@event_values    = Hash.new    ## event values
  
  @@runtime_step    = 0.1         ## step seconds used during runtime


  attr_accessor :step
  attr_accessor :now
  attr_accessor :desc
  
  attr_reader   :tasks
  attr_reader   :periodic_tasks
  attr_reader   :events
  attr_accessor :event_values
  
  #####################
  def initialize (desc)
    @desc           = desc
    @tasks          = Hash.new    ## time-based tasks
    @periodic_tasks = []          ## also time-based tasks
         
    @@kids << self
    
    reset
  end
  
  #########
  def reset
    @now            = 0.0
    @step           = 0.1
  end
  
  def self.clear_messages
    @@messages = {}
  end


  #########################
  ## Time-based methods ##
  #########################

  
  ###################################################
  def at(this_time, &do_something)
    case this_time.class.to_s
      when 'Symbol'
        @now += @step if this_time == :next
      else
        @now = this_time
    end ## end of case this_time.class
    
    @tasks[@now] = [] unless @tasks.include? @now
    @tasks[@now] << do_something
    
  end ## end of def at
  
  ##################################
  def every(period, begin_sec=0.0, end_sec=999999.9, &do_something)
    
    periodic_tasks << [begin_sec..end_sec, 0.0, period, do_something]

  end
  
  ####################
  def run(a_time=@now)
  
    puts ">"*7 + " run a_time: #{a_time}" if $debug
    
    @now = a_time
    
    @tasks.each_pair do |task_time, task_procs|
      if task_time <= @now
        puts "task_time #{task_time} -=>" if $verbose
        task_procs.each do |a_proc|
          a_proc.call
        end
        @tasks.delete task_time
      end
    end

# ASSUMES that 'run' is called each @@runtime_step time
# if not, this periodic feature will not work

    if @periodic_tasks.length > 0
    
      task_deleted = false

      @periodic_tasks.length.times do |pt_inx|

        if @periodic_tasks[pt_inx][0].include? @now

          # now is inside of the designated range

          # if timer has expired, execute the task block
          if ( @now - @periodic_tasks[pt_inx][1] ) >= @periodic_tasks[pt_inx][2]
            # do the task
            @periodic_tasks[pt_inx][3].call
            # reset the count-down to the task period
            @periodic_tasks[pt_inx][1] = @now
          end
        else
          # when current sim time has exceed the task's range
          # remove it from the task queue
          if @now > @periodic_tasks[pt_inx][0].last
            @periodic_tasks[pt_inx] = nil
            task_deleted = true
          end
        end ## end of if @periodic_tasks[pt_inx][0].include? @now
      end ## end of @periodic_tasks.length.times do |pt_inx|
      # remove all expired (@now exceeds range) periodic tasks
      @periodic_tasks.compact! if task_deleted
    end ## end of if @periodic_tasks.length > 0

    ##########################################
    ## TODO: Add conditional tasks

    puts "<"*7 + " end of run a_time: #{a_time}" if $debug
    
  end ## end of def run

  ##############################
  def advance_time(a_step=nil)
    @step = a_step unless a_step.nil?
    @now += @step
    run
  end

#########################
## Event-based methods ##
#########################


  ################
  def if(a_string)
    # TODO: complete the if method
=begin

  Conditional Tasks to be checked at each invocation of s.run

  Expecting a_string to look something like:
  
  ":e1 | :e2 | :e3"
  ":e1 or :e2 or :e3"
  ":e1 & :e2 & :e3"
  ":e1 and :e2 and :e3"

might have additional compound logical methods like

  s.any(:e1, :e2, :e3) &block
  s.or(:e1, :e2, :e3) &block
  
  s.and(:e1, :e2, :e3) &block
  s.all(:e1, :e2, :e3) &block
  s.while(:e1, :e2, :e3) &block
    
  
  this requires a new kind of tasks queue .... conditional_tasks
  
=end

  end
  
  
  ###############################
  def on(an_event, condition=true, &do_something)
    case condition.class.to_s
      when 'TrueClass'
      when 'FalseClass'
      else
        return nil
    end
    
    unless do_something.nil?
      @@events[an_event] = [] unless @@events.include? an_event
      @@events[an_event] << [condition, do_something]
      @@event_values[an_event] = nil unless @@event_values.include? an_event
      return @@event_values
    end
  
  end ## end of def on(condition
  
  ####################
  def self.subscribe(a_msg_class)
    
    a_msg_class.subscribe(IseScenario.method(:receive_message)) 
    @@messages[a_msg_class.to_s.to_sym] = [nil, nil]
        
  end



  ################
  def set an_event

    return nil unless 'Symbol' == an_event.class.to_s

    @@event_values[an_event] = true

    if @@events.include?(an_event)
      @@events[an_event].each do |event|
        event[1].call if event[0]
      end
    end

  end
 
 



  #########################################
  def self.receive_message(a_header, a_message)

    msg_sym = a_message.class.to_s.to_sym
    
    if $debug
      puts a_header.to_s
      puts a_message.to_s
    end

    @@messages[msg_sym] = [a_header, a_message]

#    self.set msg_sym
    
    @@event_values[msg_sym] = true

    if @@events.include?(msg_sym)
      @@events[msg_sym].each do |event|
        event[1].call if event[0]
      end
    end

  end
  
  ##################
  def message(a_sym)
  
    return @@messages[a_sym]
  
  end ## end of def message(a_sym)
  
 
  ##################
  def unset an_event
    puts "unset >>>" if $debug
    return nil unless 'Symbol' == an_event.class.to_s
    @@event_values[an_event] = false
    if @@events.include? an_event
      @@events[an_event].each do |event|
        event[1].call unless event[0]
      end
    end
    puts "unset <<<" if $debug
  end
  
  ##################
  def toggle an_event
    return nil unless 'Symbol' == an_event.class.to_s
    @@event_values[an_event] = (not @@event_values[an_event]) unless @@event_values[an_event].nil?

    unless @@event_values[an_event].nil?
      if @@events.include? an_event
        ev = @@event_values[an_event]
        @@events[an_event].each do |event|
          event[1].call if ev == event[0]   ## event procs are only called on true/false values
        end
      end
    end

  end
  
  #################
  def test an_event
    return nil unless 'Symbol' == an_event.class.to_s
    return @@event_values[an_event]
  end
  

#####################
## Utility methods ##
#####################


  
  ########
  def list
    puts "-"*15
    puts "Scenario Listing"
    puts "================"
    pp self
    puts
    puts "Shared Event Structures"
    puts "======================="
    pp @@event_values
    puts "-"*15
    pp @@events
    puts "-"*15
  end ## end of def list
  
  ################################
  def remark a_comment_string
    $stderr.puts a_comment_string
  end
  
  #############
  def self.instances
    return @@kids
  end
  
  #################
  def self.messages
    return @@messages
  end
  
  ###############
  def self.events
    return @@events
  end

  ###############
  def self.events=(a_hash)
    @@events = a_hash
  end

  
  #####################
  def self.event_values
    return @@event_values
  end
   
  ##############################
  def self.event_values=(a_hash)
    @@event_values = a_hash
  end
  
  
  ################################
  def self.runtime_step=(a_double)
    @@runtime_step = a_double
  end

  ################################
  def self.runtime_step
    return @@runtime_step
  end

  
  alias :assert  :set
  
  alias :retract :unset
  alias :rescend :unset
  alias :clear   :unset
  
  alias :set?    :test

end ## end of class IseScenario



