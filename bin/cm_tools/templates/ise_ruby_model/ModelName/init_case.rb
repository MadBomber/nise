module <%= model_name.to_camelcase %>

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

	def self.init_case(header=nil, message=nil)
	  puts "MonteCarlo#init_case received by:"
	  pp $run_peer_record
	  pp $run_model_record

	  # $sim_time.reset   # <=- if you are using the SimTime class, this will reset to start_time

    # Do model specific initialization stuff here that must be
    # reset for the beginning of each new monte carlo case


	  init_case_complete = InitCaseComplete.new
	  init_case_complete.publish
	end

end
