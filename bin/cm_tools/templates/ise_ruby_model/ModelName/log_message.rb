module <%= model_name.to_camelcase %>

  ###############################################
  ## A generic callback to dump incoming messages
  
  def self.log_message(a_header, a_message=nil)
  
    if $debug
      puts "Start: "+"="*60
      puts "dump_message callback in the IseRubyModel just received this message:"
      puts "#### HEADER ####"
      puts a_header.to_s
      pp a_header
      if a_message
        puts "#### MESSAGE ####"
        puts a_message.to_s
        pp a_message
      end
      puts "End:" + "-"*60
    else
      puts "Peer-Unit: #{a_header.peer_id_}-#{a_header.unit_id_} sent #{a_message.class} at frame_count_: #{a_header.frame_count_}  send_count_: #{a_header.send_count_}"
      
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
    
  end ## end of def self.log_message(a_header, a_message=nil)

end

