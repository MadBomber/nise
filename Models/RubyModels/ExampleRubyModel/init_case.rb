module ExampleRubyModel

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

	def self.init_case(header=nil, message=nil)
	  puts "MonteCarlo#init_case received by:"
	  pp $run_peer_record
	  pp $run_model_record

	  $sim_time.reset

    # Do model specific initialization stuff here that must be
    # reset for the beginning of each new monte carlo case
    
    $case_number = message.case_number_


	  init_case_complete = InitCaseComplete.new
	  init_case_complete.publish
	end

end
