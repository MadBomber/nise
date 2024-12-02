module RabbitFeeder

  ##########################################################
  ## init is invoked after a successful connection has been
  ## established with the IseDispatcher

  def self.init

    puts "The #{self.name} has over-riden the Peerrb.init method" if $debug or $verbose
    
    ##########################################################
    ## Subscribe to IseRubyModel-specific messages    
    
    $OPTIONS[:message].split(',').each do |message_name|
      Kernel.const_get(message_name).subscribe(RabbitFeeder.method(:feed_message))
    end
    

  ##############################################################################
  ## Control messages used with the FrameController and TimeController IseModels
  ## TODO: Move the subscriptions for standard messages to the Peerrb::register method
  ##       using standard callback method names based on the message name as snake case.

    #StartFrame.subscribe(     RabbitFeeder.method(:start_frame))
    StatusRequest.subscribe(  RabbitFeeder.method(:status_request))
    InitCase.subscribe(       RabbitFeeder.method(:init_case))
    EndCase.subscribe(        RabbitFeeder.method(:end_case))
    EndRun.subscribe(         RabbitFeeder.method(:end_run))
    
    puts "The subscribed hash:"

    $connection.subscribed.each_key do |k|
      begin
        amr = AppMessage.find(k)
      rescue
        amr = nil
      end
      puts "#{k}). #{amr.app_message_key} -- #{amr.description}" unless amr.nil?
    end
    

    # output something to let the user known this IseRubyModel is still alive
    EventMachine::add_periodic_timer( 30 ) do
      puts "-"*30
      puts "#{__FILE__}:  #{Time.now}" ## every 30 seconds
      $stdout.flush
    end

    # Establish the rate at which this IseRubyModel desires to be stroked
    Peerrb.rate= 0.0   # should be 0.0 if the FramedController is not being used
    
    # Tell the IseRubyPeer that this IseRubyModel is ready to run ......
    Peerrb.model_ready

  end ## end of self.init

end


