module ExampleRubyModel

  def self.amqp_test_message(a_header=nil, a_message=nil)
    puts "Got This Message: " + a_message.class.to_s
    puts "           Frame: " + a_message.frame_.to_s
    puts "       TimeStamp: " + a_message.time_stamp.to_s
    puts "           Quote: " + a_message.my_message
  end

end
