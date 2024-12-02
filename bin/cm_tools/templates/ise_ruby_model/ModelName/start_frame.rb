module <%= model_name.to_camelcase %>

  def self.start_frame(a_header=nil, a_message=nil)
    
    # $sim_time.advance_time  # <=- if you are using the SimTime library uncomment this line
    
    # do whatever is necessary during this current frame
    
    $end_frame = EndFrame.new unless defined?($end_frame)
    $end_frame.publish
    
  end

end
