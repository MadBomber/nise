################################################################
###
##  File: AmqpPublisher.rb
##  Desc: Do something with an AMQP-server outside of a normal IseModel stack
#

require 'bunny'


class AmqpPublisher


  def initialize( options={}  )
  
    
  end ## end of def initialize(  options={} )


  #################################
  # SMELL: Assumes data is a string
  def send_data(data)
  
  
  end ## end of def send_data(data)
  
  
  #################################
  def publish_message(ise_message)
    raise 'Not Implemented'
  end

end ## end of class AmqpPublisher
