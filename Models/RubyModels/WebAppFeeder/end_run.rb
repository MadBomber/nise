module WebAppFeeder

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

  def self.end_run(header=nil, message=nil)
	  puts "MonteCarlo#end_run"
	  # ... do stuff ...
	  end_run_complete = EndRunComplete.new
#  	end_run_complete.case_number_ = message.case_number_
	  end_run_complete.publish
  end

end

