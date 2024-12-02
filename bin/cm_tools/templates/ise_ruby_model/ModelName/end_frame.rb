module <%= model_name.to_camelcase %>

  def self.end_frame(a_header=nil, a_message=nil)
    puts "end_frame"
    # TODO: Explain why and EndFrame was sent and from whom.  What processing
    #       is expected beyond just acknowledging the message ...
    EndFrameOkResponse.publish
  end

end
