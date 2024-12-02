################################################################
###
##  File: SimpleProtocol.rb
##  Desc: Defines the structure of a Simple header and footer blocks
##        for use with the Simple Communications Network Protocol
##        used within NATO.  The simple protocol encapsulated several
##        different kinds of tactical data link protocols such as
##        link-11 and link-16.  When used within the context of Link-16
##        it is common to refer to the Simple protocol as Simple-J.
##
##        This file defines the generic SimpleHeader, SimpleCommon, and SimpleFooter
##        classes.  It also defines the link-16 specific SimpleJHeader, SimpleKLink16Header
##        and SimpleJFooter.
#

require 'IseMessage'

$simple_marker         = 'I6'  # 0x4936
$simple_marker_length  = $simple_marker.length

################################
$simple_header_length = 14
class SimpleHeader < IseMessage

  # packet_type_ defines the type of packet that is encapsulated between
  # the simple protocol header and footer.  The following constants define
  # known types which can be processed.
  
  LINK16_PACKET_TYPE        =  1  # link-16 encapsulated (makes this a SimpleJHeader)
  STATUS_CONFIGURATION_TYPE = 61  # Status/Configuration message is encapsulated

  def initialize(data=nil)

    super

	  item(:unsigned_char,  :sync_byte_1_)            ## fixed value signature
	  item(:unsigned_char,  :sync_byte_2_)            ## fixed value signature
	  item(:LITTLE_UINT16,  :length_)                 ## in bytes from beginning of header to end of SimpleFooter
	  item(:LITTLE_UINT16,  :sequence_num_)           ##
	  item(:unsigned_char,  :source_node_)            ##
	  item(:unsigned_char,  :source_sub_node_)        ##
	  item(:unsigned_char,  :destination_node_)       ##
	  item(:unsigned_char,  :destinatione_sub_node_)  ##
	  item(:unsigned_char,  :packet_size_)            ##
	  item(:unsigned_char,  :packet_type_)            ## value 0b00000001 means SimpleJ (i.e., Link-16)
	  item(:LITTLE_UINT16,  :transit_time_)           ##
    
    if data && data.class.to_s == 'String'
      raise NotSimpleHeader if data.length < $simple_header_length
      @raw = data[0,$simple_header_length]
      @out = ''
      unpack_message
    else
      @sync_byte_1_           = 0b01001001            # fixed value: 'I' 0d74 0x49
      @sync_byte_2_           = 0b00110110            # fixed value: '6' 0d56 0x36
      @length_                = 0b0000000000111100
      @sequence_num_          = 0b1100011001110001
      @source_node_           = 0b01111101            # Value: 125 Fixnum (7d -=> 0111_1101)
      @source_sub_node_       = 0b11001110            # Value: 206 Fixnum (ce -=> 1100_1110)
      @destination_node_      = 0b10000001            # Value: 129 Fixnum (81 -=> 1000_0001)
      @destinatione_sub_node_ = 0b11001110            # Value: 206 Fixnum (ce -=> 1100_1110)
      @packet_size_           = 0b00011010
      @packet_type_           = 0b00000001
      @transit_time_          = 0b0000000000000000
    end

    self.to_s if $debug

  end  ## end of def initialize

end ## end of class SimpleHeader 

##############################################
$simplej_header_length = $simple_header_length
class SimpleJHeader < SimpleHeader

  def initialize(data=nil)
    desc "Simple-J Header"
    super
  end

end


=begin
Link16 message(s) appear between the SimpleHeader and the SimpleFooter.

The expected order of Link16 components within the SimpleProtocol is:

  SimpleHeader
    SimpleJLink16Header
    Link16Common
    ... specific Link16 message content
  SimpleFooter

=end

###########################################
$simplej_link16_header_length = 14

class SimpleJLink16Header < IseMessage


  def initialize(data=nil)
    desc "SimpleJ Link-16 Header"
    super

	  item(:unsigned_char,  :message_sub_type_)       #                00000010
	  item(:unsigned_char,  :r_c_flag_)               #                00000000
	  item(:unsigned_char,  :net_num_)                #                00000000
	  item(:unsigned_char,  :seq_slot_count_f2_)      #                00000000
	  item(:LITTLE_UINT16,  :npg_num_)                #        0000000000000111
	  item(:LITTLE_UINT16,  :seq_slot_count_f1_)      #        0000000000000000
	  item(:LITTLE_UINT16,  :stn_)                    #        0000000000000001
	  item(:LITTLE_UINT16,  :word_count_)             #        0000000000001111
	  item(:LITTLE_UINT16,  :loopback_id_)            #        0000000000000000

    if data && data.class.to_s == 'String'
      raise NotSimpleJLink16Header if data.length < $simplej_link16_header_length
      @raw = data[0,$simplej_link16_header_length]
      @out = ''
      unpack_message
    else
      @message_sub_type_   = 0b00000010
      @r_c_flag_           = 0b00000000
      @net_num_            = 0b00000000
      @seq_slot_count_f2_  = 0b00000000
      @npg_num_            = 0b0000000000000111
      @seq_slot_count_f1_  = 0b0000000000000000
      @stn_                = 0b0000000000000001
      @word_count_         = 0b0000000000001111
      @loopback_id_        = 0b0000000000000000
    end

  end ## end of def initialize

end ## end of class SimpleJLink16Header

######################################
## The Simple footer consists of only
## a single element, a 16 bit checksum.

$simple_footer_length  = 2

class SimpleFooter < IseMessage

  def initialize(data=nil)
    desc "Simple Footer"
    super

    item(:LITTLE_UINT16, :checksum_)  ##  Checksum of the entire SimpleMessage
    
    if data && data.class.to_s == 'String'
      raise NotSimpleFooter if data.length < $simple_footer_length
      @raw = data[0,$simple_footer_length]
      @out = ''
      unpack_message
    else
      @checksum_           = 0
    end

  end ## end of def initialize

end ## end of class SimpleFooter

##############################################
$simplej_footer_length = $simple_footer_length

class SimpleJFooter < SimpleFooter
  def initialize(data=nil)
    desc "SimpleJ Footer"
    super
   end
end



