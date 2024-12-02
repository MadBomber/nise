###############################################
###
##   File:   AmqpTestMessage.rb
##   Desc:   An IseMessage to test the AMQP IseRouter
##
#

require 'AmqpMessage'

class AmqpTestMessage < AmqpMessage
  def initialize(data=nil)
    super
    desc "An IseMessage to test the AMQP IseRouter"
    item(:time_stamp, Time.now.to_f)
    item(:my_message, "Hello World")
  end
end
