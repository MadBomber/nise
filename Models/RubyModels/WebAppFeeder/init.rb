module WebAppFeeder

  ##########################################################
  ## init is invoked after a successful connections has been
  ## established with the IseDispatcher

  def self.init

    # FIXME: Logging is broken because it relied on AADSE
    #log_this "The #{self.name} has over-riden the Peerrb.init method" if $debug or $verbose
    
    $interceptor_threat_xref = Hash.new # key is interceptor_label; value is threat_label
    $unrecoverable_post_error = false
    
    ##########################################################
    ## Subscribe to IseRubyModel-specific messages
    
    $OPTIONS[:message].split(',').each do |message_name|
      Kernel.const_get(message_name).subscribe(WebAppFeeder.method(:feed_message))
    end
    

  ##############################################################################
  ## Minimum Control messages used with the FrameController and TimeController IseModels
  ## TODO: Move the subscriptions for standard messages to the Peerrb::register method
  ##       using standard callback methods based on the message name as snake case.

    StatusRequest.subscribe(  WebAppFeeder.method(:status_request))
    InitCase.subscribe(       WebAppFeeder.method(:init_case))
    EndCase.subscribe(        WebAppFeeder.method(:end_case))
    EndRun.subscribe(         WebAppFeeder.method(:end_run))
    
    # FIXME: Logging is broken because it relied on AADSE
    #log_this "The subscribed hash:"

    $connection.subscribed.each_key do |k|
      begin
        amr = AppMessage.find(k)
      rescue
        amr = nil
      end
      # FIXME: Logging is broken because it relied on AADSE
      #log_this "#{k}). #{amr.app_message_key} -- #{amr.description}" unless amr.nil?
    end

    if $running_in_the_peer
      # output something to let the user known this IseRubyModel is still alive
      EventMachine::add_periodic_timer( 30 ) do
        puts "-"*30
        puts "#{__FILE__}:  #{Time.now}" ## every 30 seconds
        $stdout.flush
      end
    end
    
    # Establish the rate at which this IseRubyModel desires to be stroked
    Peerrb.rate= 0.0
    
    # Tell the IseRubyPeer that this IseRubyModel is ready to run ......
    Peerrb.model_ready

  end ## end of self.init

end


