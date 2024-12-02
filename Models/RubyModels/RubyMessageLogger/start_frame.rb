module RubyMessageLogger

  def self.start_frame(a_header=nil, a_message=nil)
    puts "#{Time.now.to_f} Received start_frame"
  end

end
