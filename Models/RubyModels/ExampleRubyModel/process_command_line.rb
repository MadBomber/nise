module ExampleRubyModel

  def self.process_command_line

    ###################################################
    ## Print out the command line options

    puts "#{$OPTIONS[:model_name]}  ARGV: #{ARGV.join(" ")}"

    # There are many options in ruby for processing command line elements
    # You can use any of the common library or roll your own.

  end ## end of def self.proccess_command_line

end



