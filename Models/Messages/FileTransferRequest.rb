###############################################
###
##   File:   FileTransferRequest.rb
##   Desc:   Request a file from somewhere
##
#

require 'IseMessage'

class FileTransferRequest < IseMessage
  def initialize
    super
    desc "Request a file"
    item(:cstring,          :file_path_)
  end
end
