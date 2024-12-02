module RubyMessageLogger

  def self.process_command_line


    $OPTIONS[:message]        = nil
    $OPTIONS[:log_dispatcher] = false
    $OPTIONS[:log_amqp]       = false
    $OPTIONS[:all]            = false

    ARGV.options do |o|

      o.on("-m", "--message=name[,name]*", String, "Message Name(s) to log")      { |v| $OPTIONS[:message] = v }
      
      o.on("-a", "--amqp",       "Log AMQP")           { |v| $OPTIONS[:log_amqp]        = true }
      o.on("-d", "--dispatcher", "Log IseDispatcher")  { |v| $OPTIONS[:log_dispatcher]  = true }
      
      o.on("-A", "--all", "Log ALL AMQP Messages")     { |v| $OPTIONS[:all]             = true }
      
      o.on("-b", "--both",       "Log Both")           { |v| $OPTIONS[:log_amqp]        = true
                                                             $OPTIONS[:log_dispatcher]  = true
                                                       }
      
      o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
      o.parse!

    end ## end of ARGV.options do




    ###################################################
    ## Validate the command line parameters

    argument_error = Array.new

    if $OPTIONS[:log_amqp]
      unless $OPTIONS[:amqp]
        argument_error << "Can not log AMQP messages because the AMQP router was not specified."
      end
    end

    if $OPTIONS[:log_dispatcher]
      unless $OPTIONS[:dispatcher]
        argument_error << "Can not log IseDispatcher messages because the IseDispatcher router was not specified."
      end
    end

    unless argument_error.empty?
      debug_me('ERROR'){:argument_error}
      exit(1)
    end

  end ## end of def self.proccess_command_line

end



