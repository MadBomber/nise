module WebAppFeeder

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################


  def self.end_case(header=nil, message=nil)
	  puts "MonteCarlo#end_case"
	  # ... do stuff ...
	  end_case_complete = EndCaseComplete.new
#  	end_case_complete.case_number_ = message.case_number_
	  end_case_complete.publish
	end

end
