module WebAppFeeder

  def self.status_request(a_header=nil, a_message=nil)
    puts "status_request"
    osr = OkStatusResponse.new
    osr.publish
  end

end
