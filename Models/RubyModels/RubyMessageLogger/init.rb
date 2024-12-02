module RubyMessageLogger

  ##########################################################
  ## init is invoked after a successful connection has been
  ## established with the IseDispatcher

  def self.init

    puts "The #{self.name} has over-riden the Peerrb.init method" if $debug or $verbose
    
    ##########################################################
    ## Subscribe to IseRubyModel-specific messages    
    
    unless $OPTIONS[:message].nil?
      $OPTIONS[:message].split(',').each do |message_name|
        printf "Subscribing to #{message_name} ... using"
        require message_name
        if $OPTIONS[:log_dispatcher]
          Kernel.const_get(message_name).subscribe(RubyMessageLogger.method(:log_message))
          printf " :dispatcher"
        end
        if $OPTIONS[:log_amqp] and not $OPTIONS[:all]
          Kernel.const_get(message_name).subscribe(RubyMessageLogger.method(:log_amqp_message), :via => :amqp)
          printf " :amqp"
        end
        puts
      end
    else
      ISE::Log.debug "No specific set of messages was specified."
    end
    
    if $OPTIONS[:log_amqp] and $OPTIONS[:all]
      $amqp_connection.subscribe_to_all(RubyMessageLogger.method(:log_any_amqp_message))
    end
    

  ##############################################################################
  ## Control messages used with the FrameController and TimeController IseModels
  ## TODO: Move the subscriptions for standard messages to the Peerrb::register method
  ##       using standard callback method names based on the message name as snake case.

    if $OPTIONS[:dispatcher]
    
      StartFrame.subscribe(     RubyMessageLogger.method(:start_frame))
      StatusRequest.subscribe(  RubyMessageLogger.method(:status_request))
      InitCase.subscribe(       RubyMessageLogger.method(:init_case))
      EndCase.subscribe(        RubyMessageLogger.method(:end_case))
      EndRun.subscribe(         RubyMessageLogger.method(:end_run))

      %w( StartFrame StatusRequest InitCase EndCase EndRun ).each do |message_name|
        puts "Subscribing to #{message_name} ... using :dispatcher"
      end

    end

    puts "The IseDispatcher subscribed hash:"

    unless $connection.nil?
      $connection.subscribed.each_key do |k|
        begin
          amr = AppMessage.find(k)
        rescue
          amr = nil
        end
        amr_str = amr ? "#{amr.app_message_key} -- #{amr.description}" : "(No record in app_messages)"
        puts "#{k}). #{amr_str}"
      end
    end
    
    unless $amqp_connection.nil?
      $amqp_connection.subscriptions.each_pair do |key, value|
        puts "AMQP-Subscribed to #{key} with #{value.inspect}"
      end
    end
    
    
    # output something to let the user known this IseRubyModel is still alive
    EventMachine::add_periodic_timer( 30 ) do
      $stdout.puts "#{Time.now.to_f}\t#{ISE::Log.progname} is alive." ## every 30 seconds
      $stdout.flush
    end

    # Establish the rate at which this IseRubyModel desires to be stroked
    Peerrb.rate= 0.0   # should be 0.0 if the FramedController is not being used
    
    # Tell the IseRubyPeer that this IseRubyModel is ready to run ......
    Peerrb.model_ready
        
    $stdout.flush
    
  end ## end of self.init

end


