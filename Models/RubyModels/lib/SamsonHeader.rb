#####################################################################
###
##  File:  SamsonHeader.rb
##  Desc:  The base class for the header to all Samson ISE Messages.
##
#


$samson_header_length = 48

require 'IseMessage'
require 'SimMsgFlag'
require 'zlib'        ## used to calculate the CRC32

class SamsonHeader < IseMessage
  def initialize(data=nil)
    super()
    desc "Samson Header"

    item(:ascii_string2, :magic_)       ##  Always 'SN'
    item(:unsigned_char, :version_id_)  ##  Current header form is version 1
    item(:unsigned_char, :dispatched_)  ##  Always a zero; used by the dispatcher

    item(:ACE_UINT32, :run_id_)         ##  Run ID
    item(:ACE_UINT32, :peer_id_)        ##  Model(/Peer) ID
    item(:ACE_UINT32, :msg_id_)         ##  Run Message ID  (Run dependent)

    item(:ACE_UINT16, :app_msg_id_)     ##  Application Message ID  (Run independent)
    item(:ACE_UINT16, :unit_id_)        ##  Instance identifier
    item(:ACE_UINT32, :flags_)          ##  Bit Flags
    item(:ACE_UINT32, :type_)           ##  Message Type Enumeration

    item(:ACE_UINT32, :dest_peer_id_)   ##  For direct model-to-model communications
    item(:ACE_UINT32, :frame_count_)    ##  Frame Counter
    item(:ACE_UINT32, :send_count_)     ##  Send Counter
    item(:ACE_UINT32, :message_crc32_)  ##  CRC32 of the data portion of an IseMessage
    item(:ACE_UINT32, :message_length_) ##  Data Length that follows this header
    
    if data && data.class.to_s == 'String'
      raise NotSamsonHeader if data.length < $samson_header_length
      @raw = data[0,$samson_header_length]
      @out = ''
      unpack_message
    else
      @magic_           = 'SN'
      @version_id_      = 1
      @dispatched_      = 0
      
      @run_id_          = $run_record.id
      @peer_id_         = $run_peer_record.id
      @msg_id_          = 0     ## RunMessage.id
      
      @app_msg_id_      = 0     ## AppMessage.id from the IseDatabase
      @unit_id_         = $OPTIONS[:unit_number]
      @flags_           = 0
      @type_            = 0     ## becoming but not yet OBE -- working toward use ofapp_msg_id_ only
      
      @dest_peer_id_    = 0     ## ?? only used when sending p2p messages (contains process_id from dispatcher on hello handshake)
      @frame_count_     = 0
      @send_count_      = 0
      @message_crc32_   = 0
      @message_length_  = 0
      
      
    end

#    self.to_s if $debug

  end  ## end of def initialize
  
  
  ########
  def to_s
    a_str = super
    return a_str += "\n" + SimMsgFlag.to_s(@flags_) + "\n"
  end
  
  def unpack_message
    super
    puts "\n#{SimMsgFlag.to_s(@flags_)}\n" if $debug or $debug_io
  end
 
end ## end of class SamsonHeader

