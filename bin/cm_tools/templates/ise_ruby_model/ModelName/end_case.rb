module <%= model_name.to_camelcase %>

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################


  def self.end_case(header=nil, message=nil)
	  puts "MonteCarlo#end_case"

	  # ... do stuff ...
	  
	  # The IseJob controller has determined that the current monte carlo
	  # case has ended.  it is telling all IseModels to do whatever process
	  # is required at the end of a case.  After the model complete its
	  # EndCase process, it must acknowledge that is is complete by publishing
	  # the EndCaseComplete message.
	  
	  end_case_complete = EndCaseComplete.new
	  end_case_complete.publish
	end

end
