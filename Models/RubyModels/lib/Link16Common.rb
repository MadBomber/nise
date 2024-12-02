################################################################
###
##  File: Link16Common.rb
##  Desc: Used to determine what kind of Link16 message is in the buffer.
##        Required for unpacking a buffer with the correct Link-16 format.
##        Not used for publishing or defining a new Link-16 message.
#

require 'Link16Message'

################################
class Link16Common < Link16Message

  def initialize(data=nil)
    super     ## Link16Message inserts the first common items (4) accounting for the first 13 bits
    desc "Link16 Common Message Segment"

    # Common fields are inherented from Link16Message
    # This unused_ fields is used to make a full 16-bit word
    # to ensure proper offset for the common fields.
	  type(:unused_,            '000')

    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end
    
  end ## end of def initialize
  
end ## end of class Link16Common



