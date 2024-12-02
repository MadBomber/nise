module ExampleRubyModel

  def self.start_frame(a_header=nil, a_message=nil)
    
    $sim_time.advance_time  # <=- if you are not using the SimTime library delete this line
    
    if ( a_header.frame_count_ <= 1 ) and ( 1 == $OPTIONS[:unit_number] )
    
      rc = RunConfiguration.new
      
      rc.run_id_      = $run_record.id
      rc.created_at_  = $run_record.created_at.to_f
      rc.job_id_      = $run_record.job_id
      rc.debug_flags_ = $run_record.debug_flags
      rc.guid_        = $run_record.guid
      rc.input_dir_   = $run_record.input_dir
      rc.output_dir_  = $run_record.output_dir

      rc.publish    
    
    end
    
    unless $my_quotes.empty?
      $amqp_test_message.frame_     = $sim_time.offset
      $amqp_test_message.time_stamp = Time.now.to_f
      $amqp_test_message.my_message = $my_quotes.pop
      $amqp_test_message.publish(:details => false)
    end

    $end_frame = EndFrame.new unless defined?($end_frame)
    $end_frame.publish
        
  end

end

