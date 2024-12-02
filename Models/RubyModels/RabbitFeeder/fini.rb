module RabbitFeeder

  #############################################################################
  ## fini is invoked after the connection to the IseDispatcher has been dropped
  
  def self.fini
    puts "The IseRubyModel has over-riden the Peerrb.fini method" if $debug or $verbose
  
    # The fini method is called when the IseRubyModel is in the process of terminating.
    # This is a good time to dump any collected statistics or such to the the log file.
  

  end ## end of def self.fini

end
