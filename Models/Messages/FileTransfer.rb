###############################################
###
##   File:   FileTransfer.rb
##   Desc:   Transfer a file to somewhere
##
#

require 'IseMessage'

class FileTransfer < IseMessage
  def initialize
    super
    desc "Transfer a file"
    item(:cstring,          :file_path_)
    item(:p4string,         :file_contents_)
  end
end
