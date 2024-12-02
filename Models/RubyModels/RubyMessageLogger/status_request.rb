module RubyMessageLogger

  def self.status_request(a_header=nil, a_message=nil)
    puts "#{Time.now.to_f} Received status_request"
    # .. do stuff ... like dump current state
    # The StatusRequest message is sent by the FramedController
    # when it senses that the IseJob may be stalled.
    OkStatusResponse.publish
  end

end
