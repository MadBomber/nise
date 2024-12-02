module RabbitFeeder

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

  def self.end_run(header=nil, message=nil)
	  puts "MonteCarlo#end_run"

	  # ... do stuff ...
	  
	  # The master controller for this IseJob has determined that the
	  # IseJob should be terminated.  The EndRun message was sent to signal
	  # each IseModel that the IseJob is terminating.  It may not be
	  # necessary to do anything at this point other than acknowledge the
	  # EndRun message with an EndRunComplete BECAUSE ... the IsePeer will
	  # be calling the fini method after the connection to the IseDispatcher
	  # has been closed.  The fini method is the normal place where the
	  # final data from the model is processed.
	  
	  end_run_complete = EndRunComplete.new
	  end_run_complete.publish
  end

end

