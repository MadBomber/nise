module WebAppFeeder

  def self.process_command_line

    ############################################
    ## process command line parameters

    $OPTIONS[:message] = nil

    ARGV.options do |o|

      o.on("", "--sev=SystemEnvironmentVariable", String, "The SEV that contains the URL to feed")      { |v| $OPTIONS[:sev] = v }
      o.on("-m", "--message=name[,name]*", String, "Message Name(s) to feed")      { |v| $OPTIONS[:message] = v }
      o.on("-#", "Delimits the start of IseRubyModel options")      { |x| }
      o.parse!

    end ## end of ARGV.options do

    $OPTIONS[:url] = ENV[$OPTIONS[:sev]]

    if $OPTIONS[:message]
      puts "Begin feeding the following messages:"
      $OPTIONS[:message].split(',').each do |message_name|
        printf "\t#{message_name} ... "
        load_result = require message_name
        puts  load_result ? 'loaded.' : 'already loaded.'
      end
      puts
      puts "to the web applicaiton pointed to by the system environment variable:"
      puts "  #{$OPTIONS[:sev]} whose value is -=> #{$OPTIONS[:url]}"
    end

    unless $OPTIONS[:url]
      throw "ERROR: URL not set by system environment variable: #{$OPTIONS[:sev]}"
    end

    ###################################################
    ## Print out the command line options

    pp ARGV


  end ## end of def self.proccess_command_line

end



