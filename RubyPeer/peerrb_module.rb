##########################################################
###
##  File: peerrb_module.rb
##  Desc: Defines the default behavior for IseRubyModels
##        Establishes hooks init, fini, et.al
#

require 'IseRouter'
require 'string_mods'

require 'IseMessage'
require 'ControlMessages'

require 'monte_carlo_module'

module Peerrb
  VERSION = '0.0.2'
  @@default_one = 1.0
  @@default_two = 2.0

  [:default_one, :default_two].each do |sym|
    class_eval <<-EOS, __FILE__, __LINE__
      def self.#{sym}
        if defined?(#{sym.to_s.upcase})
          #{sym.to_s.upcase}
        else
          @@#{sym}
        end
      end

      def self.#{sym}=(obj)
        @@#{sym} = obj
      end
    EOS
  end
  
  ##################################################
  ## Allow IseRubyModel to over-ride require methods
  
  def self.register(model_name, ops={})
  
    ISE::Log.info "Registering #{model_name}"
    
    # Transfer to a local variable so I can override
    debug = $debug
    debug = true
    
    auto_sub_messages = Array.new
    
    model_constant = model_name.to_constant
  
    if debug
      puts "Attempting to register #{model_name} with the following options:"
      pp ops
    end
            
    options = {  :monte_carlo       => false,
                 :framed_controller => false,
                 :timed_controller  => false,
                 :auto_subscribe    => false,
                 :messages          => []
              }.merge(ops)
    
    options[:messages] << :InitEvent
  
    
    auto_sub_messages << :InitEvent     if options[:auto_subscribe]

  
    [:init, :fini, :info].each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__
        def self.#{sym}
          #{model_name}.#{sym}
        end
      EOS
    end

    if options[:monte_carlo]    
      MonteCarlo.register(model_name)
      options[:messages] << [ :InitCase,    :InitCaseComplete,
                              :EndCase,     :EndCaseComplete,
                              :EndRun,      :EndRunComplete
                            ]

      auto_sub_messages << [:initCase, :EndCase, :EndRun]     if options[:auto_subscribe]
      
    end
    
    if options[:framed_controller]
      options[:messages] << [ :StartFrame,  :EndFrame ]
      auto_sub_messages  << :StartFrame     if options[:auto_subscribe]
    end
    
    if options[:timed_controller]
      options[:messages] << [ :AdvanceTime ]
      auto_sub_messages  << :AdvanceTime     if options[:auto_subscribe]
    end


    unless options[:messages].empty?
      options[:messages].flatten.uniq.each do |msg|
        printf "Loading message: #{msg} ... " if debug
        begin
          result = require(msg.to_s)
          puts (result ? 'done.' : 'already loaded.')  if debug
          msg_instance = eval "#{msg}.new"
          msg_instance.register     # Adds message to the IseDatabase app_messages table if not already there.
        rescue
          puts "WARNING: Can not find an IseMessage with this name: #{msg}"
        end
      end
    end


    # FIXME: There may be no fix.  While auto subscription to the common control messages is a good idea,
    #        the sequence of what happens in the overall peerrb startup does not support it.  For
    #        example, register is called BEFORE connections have been established to any IseRouter.
    if options[:auto_subscribe]
      auto_sub_messages.flatten.uniq.each do |message_class_symbol|
        auto_subscribe(model_constant, message_class_symbol)  # SMELL: which IseRouter ??
      end
    end


    return options[:messages].flatten.uniq
    
  end ## end of def self.register(model_name)
  
  
  #######################
  def self.auto_subscribe(module_or_class, message_symbol, router=IseRouter::DEFAULT_ROUTER)
    message_str             = message_symbol.to_s
    message_class           = message_str.to_constant
    callback_method_symbol  = message_str.to_snakecase.to_sym
    
    ISE::Log.debug "auto-sub #{message_str} w/cb #{module_or_class}.#{callback_method_symbol}"
    
    # NOTE: This subscription happens before any libraries are loaded by the model
    #       At this time we do not know wither the callback method actually exists.
    message_class.subscribe( module_or_class.method(callback_method_symbol), router )
  end
  
  
  ########
  def self.rate=(a_float)
    real_float = Float(a_float)
    $run_model_record.rate = real_float
  end
  
  ########
  def self.rate!(a_float)
    self.rate = a_float
    $run_model_record.save_with_dirty!
  end
 
  
  ########
  def self.set_status(an_integer, a_string="Status Updated")
    puts "Peerrb.set_status with #{an_integer} and #{a_string}" if $debug or $verbose
    real_integer  = Integer(an_integer)
    real_string   = a_string.to_s
    $run_model_record.status          = real_integer
    $run_model_record.extended_status = real_string
  end

  
  ########
  def self.set_status!(an_integer, a_string="Status Updated")
    puts "Peerrb.set_status! with #{an_integer} and #{a_string}" if $debug or $verbose
    self.set_status(an_integer, a_string)
    $run_model_record.save!               # NOTE: was save_with_dirty!
  end

  ########################
  def self.model_ready?
    puts "Peerrb.model_ready?" if $debug or $verbose
    return $run_model_record.model_ready
  end

  ####################
  def self.model_ready
    puts "Peerrb.model_ready" if $debug or $verbose
    $run_model_record.model_ready = true
  end
  
  #####################
  def self.model_ready!
    puts "Peerrb.model_ready!" if $debug or $verbose
    self.model_ready
    set_status!(1, "Ready To Run")
  end

   
  ########
  def self.init
    puts "Default Peerrb.init; expect IseRubyModel to over-ride" if $debug or $verbose
    self.model_ready
  end ## end of def init
  
  ########
  def self.fini
    puts "Default Peerrb.fini; expect IseRubyModel to over-ride" if $debug or $verbose
  end ## end of def fini

  ########
  def self.info
    puts "Default Peerrb.info; expect IseRubyModel to over-ride" if $debug or $verbose
  end ## end of def info

  ########
  def self.really_fini
    puts "Peerrb.really_fini" if $debug or $verbose
    $run_model_record.status = 0
    $run_model_record.extended_status = "Done"
    $run_model_record.save
  end ## end of def fini
  
end ## end of module Peerrb

