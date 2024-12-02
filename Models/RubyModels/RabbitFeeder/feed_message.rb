module RabbitFeeder

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

	def self.feed_message(header=nil, message=nil)
	  puts "received: #{message.class}"

    # Pass the message to the AMQP IseRouter
	  message.publish :via => :amqp   # TODO: Might want to fake who the message is from.  As is
	                                  #       the routing key will be built with the message coming
	                                  #       from me.  We might want the "from" component to reflect
	                                  #       the run_peer.id of the actual sender which is available
	                                  #       in the header.  So think about added a new hash
	                                  #       option like      :from => header.peer_id_
	end

end
