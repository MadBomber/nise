module RabbitFeeder

  def self.process_command_line

    ############################################
    ## process command line parameters

    $OPTIONS[:message] = nil

    ARGV.options do |o|

      o.on("-m", "--message=name[,name]*", String, "Message Name(s) to feed")      { |v| $OPTIONS[:message] = v }
      o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
      o.parse!

    end ## end of ARGV.options do



    if $OPTIONS[:message]
      puts "Begin feeding the following messages:"
      $OPTIONS[:message].split(',').each do |message_name|
        printf "\t#{message_name} ... "
        load_result = require message_name
        puts  load_result ? 'loaded.' : 'already loaded.'
      end
      puts
      puts "to the AMQP Server pointed to by the system environment variable:"
      puts "  AMQP_HOST: #{ENV['AMQP_HOST']}"
      puts "  AMQP_PORT: #{ENV['AMQP_PORT']}"
    end


    ###################################################
    ## Print out the command line options

    pp ARGV


  end ## end of def self.proccess_command_line

end



