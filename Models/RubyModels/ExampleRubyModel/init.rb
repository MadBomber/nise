module ExampleRubyModel

  ##########################################################
  ## init is invoked after a successful connection has been
  ## established with the IseDispatcher

  def self.init

    debug_me if $debug or $verbose
    
    ##########################################################
    ## Subscribe to IseRubyModel-specific messages

#   vvvvvvvvvvvvv  The message name
#   vvvvvvvvvvvvv        Notice the colon in front of the callback method name 
    AmqpTestMessage.subscribe(        ExampleRubyModel.method(:amqp_test_message))
 
    $amqp_test_message = AmqpTestMessage.new
    

  ##############################################################################
  ## Control messages used with the FrameController and TimeController IseModels
  ## TODO: Move the subscriptions for standard messages to the Peerrb::register method
  ##       using standard callback method names based on the message name as snake case.

    StartFrame.subscribe(     ExampleRubyModel.method(:start_frame))
    InitCase.subscribe(       ExampleRubyModel.method(:init_case))
    EndCase.subscribe(        ExampleRubyModel.method(:end_case))
    EndRun.subscribe(         ExampleRubyModel.method(:end_run))
    
    puts "The subscribed hash:"

    $connection.subscribed.each_key do |k|
      begin
        amr = AppMessage.find(k)
      rescue
        amr = nil
      end
      puts "#{k}). #{amr.app_message_key} -- #{amr.description}" unless amr.nil?
    end
    
    $amqp_connection.subscribed.each {|m| puts "AMQP Subscribed to: #{m}"}
    

    # output something to let the user known this IseRubyModel is still alive
    EventMachine::add_periodic_timer( 30 ) do
      puts "-"*30
      puts "#{__FILE__}:  #{Time.now}" ## every 30 seconds
      $stdout.flush
    end

    # Establish the rate at which this IseRubyModel desires to be stroked
    Peerrb.rate= 3.3

    
    # Tell the IseRubyPeer that this IseRubyModel is ready to run ......
    Peerrb.model_ready

  end ## end of self.init

end


