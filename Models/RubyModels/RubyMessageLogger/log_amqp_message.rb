module RubyMessageLogger
  
  ###############################################
  ## A generic callback to dump incoming messages
  ## from RabbitMQ the AMQP-server IseRouter
  
  def self.log_amqp_message(a_header, a_message, delivery_details={})
  
    if $debug
      puts "Start: "+"="*60
      puts "log_amqp_message callback in the IseRubyModel just received this message:"
      if a_header
        puts "#### HEADER ####"
        puts a_header.to_s
        pp a_header
      end

      unless delivery_details.empty?
        puts "#### DELIVERY DETAILS ####"
        pp delivery_details
      end

      if a_message
        puts "#### MESSAGE ####"
        puts a_message.to_s
        pp a_message
      end
      unless delivery_details.empty?
        puts "#### DELIVERY DETAILS ####"
        pp delivery_details
      end
      puts "End:" + "-"*60
    else
      puts "Routing Key: #{delivery_details[:routing_key]}"

      pp delivery_details
      
      if a_message.msg_items.length > 0
      
        max_length = 0
        
        a_message.msg_items.each do |mi|
          mi_l=mi[0].to_s.length
          max_length = mi_l if mi_l > max_length
        end
        
        a_message.msg_items.each do |mi|
          mi_sym   = mi[0]
          mi_s     = mi_sym.to_s
          padding  = max_length - mi_s.length + 1
          mi_value = a_message.instance_variable_get("@#{mi_sym}")
          puts "   #{mi_s}:" + " "*(padding) + "#{mi_value}"
        end
        
      end ## end of if a_message.msg_items.length > 0
      
    end ## end of if $debug
    
    $stdout.flush   ## default ruby buffer size is 32k; default only flushes when buffer full
    
  end ## end of def self.log_amqp_message(a_header, a_message=nil, delivery_details)

end

