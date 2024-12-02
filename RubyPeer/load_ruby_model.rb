##########################################################
###
##  File: load_ruby_model.rb
##  Desc: Process the command line
#


puts "Entering: #{File.basename(__FILE__)}"  if $debug or $verbose


#############################################################
## Load the IseRubyModel and all of its libraries


$stderr.puts "Loading IseRubyModel: #{$OPTIONS[:model_name]} using library file: #{$OPTIONS[:library]} ..." if $debug or $verbose

begin
  require $OPTIONS[:library]
rescue MissingSourceFile => e
  $stderr.puts "... unable to load model.  #{e}"
  $stderr.puts "    Suspect the system environment variable RUBYLIB"
  $stderr.puts "    does not contain the directory where #{$OPTIONS[:library]} is located."
  $stderr.puts "    RUBYLIB -=> #{ENV['RUBYLIB']}"
  $stderr.puts "    $LOAD_PATH -=> #{$LOAD_PATH}"
# These deletes are now done by the at_exit block found in peerrb.rb
#  $run_model_record.delete
#  $run_peer_record.delete
  exit(-1)
end

$run_model_record.model_ready       = 0
$run_model_record.status            = 0
$run_model_record.extended_status   = "Almost Ready"
$run_model_record.save



puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose

