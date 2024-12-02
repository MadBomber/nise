module <%= model_name.to_camelcase %>

  #############################################################################
  ## fini is invoked after the connection to the IseDispatcher has been dropped
  
  def self.fini
    puts "The IseRubyModel has over-riden the Peerrb.fini method" if $debug or $verbose
  
    # The fini method is called when the IseRubyModel is in the process of terminating.
    # This is a good time to dump any collected statistics or such to the the log file.
  
    # The follow is an example.  It dumps the msg_queue used within the RubyPeer when
    # the $debug flag is set true.
    
    if $debug    
      puts "-"*15
      puts "$connection.msg_queue contains these messages:"
      $connection.msg_queue.each do |mq|
        puts "#{mq[0]} -=> #{mq[1].to_hex}"
      end

      puts "-"*15
      puts "$connection.out_msg contains these messages:"
      $connection.out_msg.each do |mq|
        puts "#{mq[0]} -=> #{mq[1].to_hex}"
      end
    end

  end ## end of def self.fini

end
