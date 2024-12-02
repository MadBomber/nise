module <%= model_name.to_camelcase %>

  ##########################################################
  ## init is invoked after a successful connection has been
  ## established with the IseDispatcher

  def self.init

    puts "The #{self.name} has over-riden the Peerrb.init method" if $debug or $verbose
    
    ##########################################################
    ## Subscribe to IseRubyModel-specific messages    
    
=begin
#   vvvvvvvvvvvvv  The message name
#   vvvvvvvvvvvvv        Notice the colon in front of the callback method name 
    ThreatWarning.subscribe(          <%= model_name.to_camelcase %>.method(:threat_warning))
    PrepareToEngageThreat.subscribe(  <%= model_name.to_camelcase %>.method(:prepare_to_engage_threat))
    EngageThreat.subscribe(           <%= model_name.to_camelcase %>.method(:engage_threat))
    CancelEngageThreat.subscribe(     <%= model_name.to_camelcase %>.method(:cancel_engage_threat))
    
    ThreatImpacted.subscribe(         <%= model_name.to_camelcase %>.method(:remove_active_threat))
    ThreatDestroyed.subscribe(        <%= model_name.to_camelcase %>.method(:remove_active_threat))
=end
    

  ##############################################################################
  ## Control messages used with the FrameController and TimeController IseModels
  ## TODO: Move the subscriptions for standard messages to the Peerrb::register method
  ##       using standard callback method names based on the message name as snake case.

    StartFrame.subscribe(     <%= model_name.to_camelcase %>.method(:start_frame))
    StatusRequest.subscribe(  <%= model_name.to_camelcase %>.method(:status_request))
    InitCase.subscribe(       <%= model_name.to_camelcase %>.method(:init_case))
    EndCase.subscribe(        <%= model_name.to_camelcase %>.method(:end_case))
    EndRun.subscribe(         <%= model_name.to_camelcase %>.method(:end_run))
    
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
    Peerrb.rate= 0.0 # or use $sim_time.step_seconds   # should be 0.0 if the FramedController is not being used
    
    # Tell the IseRubyPeer that this IseRubyModel is ready to run ......
    Peerrb.model_ready

  end ## end of self.init

end


