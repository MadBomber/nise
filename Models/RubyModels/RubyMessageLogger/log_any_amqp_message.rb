
require 'rubygems'
require 'json'
require 'pp'

module RubyMessageLogger
  
  ###############################################
  ## A generic callback to dump incoming messages
  ## from RabbitMQ the AMQP-server IseRouter
  
  def self.log_any_amqp_message(received_message={})
  
    puts
    puts "-"*40
    puts "Header: #{received_message[:header].inspect}"

    puts "Delivery Details:"
    pp received_message[:delivery_details]

    puts "Message Payload:"
    pp JSON.parse received_message[:payload]

    $stdout.flush   ## default ruby buffer size is 32k; default only flushes when buffer full
    
  end ## end of def self.log_amqp_message(a_header, a_message=nil, delivery_details)

end

