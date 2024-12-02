module <%= model_name.to_camelcase %>
  
  ################################################################################
  ## info is invoked to provide status information about the state of the IseModel
  
  def self.info
    puts "The IseRubyModel has over-riden the Peerrb.info method"   if $debug or $verbose
    
    # do something
    # TODO: Clarify when the info methor is being called and for what purpose.
    #       Within the context of the IseRubyModel it does not look to be very useful
    
  end ## end of def self.info

end

