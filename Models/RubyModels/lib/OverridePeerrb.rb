######################################################################
###
##  File: OverridePeerrb.rb
##  Desc: The standard IseMessage publication process __assumes__ that it is
##        running within the context of an IseRubyPeer.  This library
##        overrides that assumption to allow various other methods for
##        message publication.
##
## TODO: Add stuff to comply with IseRouterConcept
#

require 'SamsonHeader'

$app_message_cache = Hash.new

##################################################################
## Over-rid IseMessage#publish for direct publication of a message
## IseMessage __assumes__ that it is being used with the Peerrb
## event_machine loop.  This over-ride gets rid of that assumption.
##
## TODO: This technique is not compatiable with the latest edge_with_amqp branch
#

class IseMessage

  # TDV: add options hash
  def publish(header=nil)       ## over-ride instance method
    $stderr.puts "#{self.class} is publishing ..." if $debug

    # TDV: get from options hash
    if header.nil?
      if @msg_header.nil?
        @msg_header = SamsonHeader.new

        app_message_key = self.class.to_s
        
        unless $app_message_cache.include?(app_message_key)
          $app_message_cache[app_message_key] = AppMessage.find_by_app_message_key(app_message_key)
        end
        
        app_message_id = $app_message_cache[app_message_key].id




        @msg_header.run_id_         = Run.last.id  ##  Run ID
        @msg_header.peer_id_        = 161  ##  Model(/Peer) ID   ????? sender or receiver ??
        @msg_header.msg_id_         = RunMessage.find(@msg_header.run_id_, app_message_id)['id'] ##  Run Message ID  (Run dependent)

        @msg_header.app_msg_id_     = app_message_id        ##  Application Message ID  (Run independent)
        @msg_header.unit_id_        = 0                      ##  Instance identifier
        @msg_header.flags_          = 0                      ##  Bit Flags
        @msg_header.type_           = SimMsgType.type_ :DATA ##  Message Type Enumeration

        @msg_header.dest_peer_id_   = 0  ##  For direct model-to-model communications
        @msg_header.frame_count_    = 0  ##  Frame Counter
        @msg_header.send_count_     = 0  ##  Send Counter
        @msg_header.message_crc32_  = 0  ##  CRC32 of the data portion of an IseMessage
        @msg_header.message_length_ = 0  ##  Data Length that follows this header

      end
    else
      @msg_header = header
    end
    
    pack_message(:details => false) # set true for debugging output

    @msg_header.message_crc32_ = Zlib.crc32(@out)  ##  CRC32 of the data portion of an IseMessage
    @msg_header.message_length_ = @out.length       ##  Data Length that follows this header

    @msg_header.pack_message(:details => false)

    $stderr.puts "  #{self.inspect}" if $debug
    
    data_out = @msg_header.out + @out
    
    $stderr.puts data_out.to_hex  if $debug

    data_out
  end

end ## end of modes to class IseMessage

