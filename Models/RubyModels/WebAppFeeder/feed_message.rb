module WebAppFeeder

  ###############################################
  ## A generic callback to dump incoming messages
  
  def self.feed_message(a_header, a_message=nil)
  
    unless $unrecoverable_post_error
      if $debug
        puts "Start: "+"="*60
        puts "feed_message callback in the WebAppFeeder just received this message:"
        puts "#### HEADER ####"
        puts a_header.to_s
        pp a_header
        if a_message
          puts "#### MESSAGE ####"
          puts a_message.to_s
          pp a_message
        end
        puts "End:" + "-"*60
        $stdout.flush   ## default ruby buffer size is 32k; default only flushes when buffer full
      end ## end of if $debug
      
      field_values_hash = a_message.to_h.merge(
        { # Merging selected fields from the message header
          "run_id_"       => a_header.run_id_,
          "frame_count_"  => a_header.frame_count_
        }
      )
      
      msg_name = a_message.class.to_s
      
      begin
        $web_app[msg_name].post( field_values_hash ) { |response, thing|
          unless 200 == response.code
            puts "Bad Post Response Code: #{response.code} msg_name: #{msg_name}, url: #{$web_app.url}"
            puts "thing: #{thing.inspect}"
          end
        }
      rescue Exception => e
        debug_me("Abnormal Termination #{e}"){:$web_app}
        # $unrecoverable_post_error = true
      end
    end # unrecoverable error
    
  end ## end of def self.feed_message(a_header, a_message=nil)

end

