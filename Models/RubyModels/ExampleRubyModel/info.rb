module ExampleRubyModel
  
  ################################################################################
  ## info is invoked to provide status information about the state of the IseModel
  
  def self.info
    puts "The IseRubyModel has over-riden the Peerrb.info method"   if $debug or $verbose
  end ## end of def self.info

end

