################################################################
###
##  File: SimpleCommon.rb
##  Desc: Defines the structure of a Simple common fields
##        following a SimpleJ Header with packet_type_ of 61
##
##  In the Simple Protocol, a packet_type_ 61 indicates a
##  Status/Configuration message.  There are several such messages.
##  They each start with a common 16-bit word that defines the
##  message_subtype_ and the number_of_words that comprise that
##  message.
#

require 'IseMessage'

################################
$simple_common_length = 2
class SimpleCommon < IseMessage

  def initialize(data=nil)
    super

	  item(:unsigned_char,  :message_subtype_)  ## what kind of message follows
	  item(:unsigned_char,  :number_of_words_)  ## how many words comprise that message

    if data && data.class.to_s == 'String'
      raise NotSimpleCommon if data.length < $simple_common_length
      @raw = data[0,$simple_common_length]
      @out = ''
      unpack_message
    end

  end ## end of def initialize
  
end ## end of class SimpleCommon
