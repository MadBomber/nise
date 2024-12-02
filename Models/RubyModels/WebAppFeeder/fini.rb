module WebAppFeeder

  #############################################################################
  ## fini is invoked after the connection to the IseDispatcher has been dropped
  
  def self.fini
    puts "The IseRubyModel has over-riden the Peerrb.fini method" if $debug or $verbose
  
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
