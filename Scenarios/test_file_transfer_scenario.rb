#############################################################################
###
##  Name:   test_file_transfer_scenario.rb
##
##  Desc:   A test scenario for the transfer of a file inside an IseMessage
##          Makes use of the :cstring and :p4string item types
##

require 'pathname_mods'


######################################
## require all the messages to be sent

require 'FileTransferRequest'
require 'FileTransfer'
require 'EndRun'


############################################################
## instantiate a new scenario with a single line description

s = IseScenario.new "Testing the ability to transfer files in an IseMessage"


s.step = 1.0    ## time step in decimal seconds

s.at(0.0) do
  s.remark "Let the testing begin"

  IseScenario.subscribe(FileTransferRequest)
  IseScenario.subscribe(FileTransfer)
  
end

some_random_time = rand(5) + 1

s.at(some_random_time) do
  a_message = FileTransferRequest.new
  a_message.file_path_   = __FILE__.to_s
  a_message.publish
  s.remark "== Published FileTransferRequest Message =="
end

s.every(5.0) do
  s.remark "#{Time.now}"
end


# terminate after a minute if file transfer has not already completed
s.at(60.0) do
  EndRun.new.publish
  s.remark "== Published EndRun Message =="
end

#########################################################################
s.on(:FileTransferRequest) do
  file_path = Pathname.new(s.message(:FileTransferRequest)[1].file_path_)
  
  ft_message            = FileTransfer.new
  ft_message.file_path_ = file_path.to_s
    
  s.remark "== Received File Transfer Request for: #{file_path}"  
  
  ft_message.file_contents_ = ""
  
  file_path.each_line {|a_line| ft_message.file_contents_ << a_line}
  
  ft_message.publish
  
end

#########################################################################
s.on(:FileTransfer) do
  file_path = Pathname.new(s.message(:FileTransfer)[1].file_path_)
  puts "Received this file: #{file_path}"
  puts s.message(:FileTransfer)[1].file_contents_
  EndRun.new.publish
end

s.list  if $debug


## The End
##################################################################

