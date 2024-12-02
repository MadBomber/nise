module WebAppFeeder

  ##########################################
  ## Standard MonteCarlo Message Handlers ##
  ##########################################

  def self.step(header=nil, message=nil)
	  puts "MonteCarlo#step"
    # ... do stuff ...
    TimeAdvanced.published
  end

end
