#####################################################
###
##  File:  SimMsgFlag.rb
##  Desc:  Must be kept in sync with Common/SimMsgFlag.h
#

class SimMsgFlag

  class InvalidSimMsgFlagError < RuntimeError; end
  
  @@my_instance = nil
  attr_reader :my_mask
  
  ##############
  def initialize
    self.new
  end
  
  
  ###################
  def self.to_s(flag_value=0xffff)
  
    self.new unless @@my_instance
    
    a_str = "A flag value of #{flag_value} (0x#{flag_value.to_s(16)}) means:\n"
    @my_mask.each do |k, v|
      a_str += "\t#{k} (0x#{v.to_s(16)})\n" if self.test flag_value, k
    end
    
    return a_str
  
  end
  
  #########################
  ## set some flags
  def self.enable(flags=[])
    flag_value = 0
    flags.each do |f|
      flag_value = flag_value | @my_mask[f]
    end
    return flag_value
  end
  
  #########################
  ## TODO: disable some flags
  def self.disable(flags=[])
    flag_value = 0
    return flag_value
  end


  #######################
  def self.test(flag_value, mask_name)
  
    self.new unless @@my_instance

=begin
$stderr.puts ">"*15
$stderr.puts "flag_value:          #{sprintf '0x%08x', flag_value}"
$stderr.puts "mask_name:           #{mask_name}"
$stderr.puts "@my_mask[mask_name]: #{sprintf '0x%08x', @my_mask[mask_name]}"
$stderr.puts "& result:            #{sprintf '0x%08x', (flag_value & @my_mask[mask_name])}"
$stderr.puts "== result:           #{@my_mask[mask_name] == (flag_value & @my_mask[mask_name])}"
$stderr.puts "<"*15
=end
     
    return @my_mask[mask_name] == (flag_value & @my_mask[mask_name])
  
  end


##########################################################
private

  def self.new
  
    return @@my_instance if @@my_instance
    
    @@my_instance = self
      
    @my_mask          = Hash.new


#  First Nibble sets typing/control  (default is data)
		@my_mask[:object]       = 0x00000001
		@my_mask[:strip_header] = 0x00000002
		@my_mask[:trace]        = 0x00000004
		@my_mask[:log_it]       = 0x00000008
		
#  Second Nibble is encoding  (default is NO encoding)
		@my_mask[:b64_encode] = 0x00000010
		@my_mask[:gzip]       = 0x00000020
		@my_mask[:b16_encode] = 0x00000040
		
# Third nibble is for routing (default is pub/sub)
		@my_mask[:master_only]  = 0x00000100
		@my_mask[:nowhere]      = 0x00000200
		@my_mask[:job]          = 0x00000400
		@my_mask[:p2p]          = 0x00000800
		@my_mask[:p2ch]         = 0x00001000
		@my_mask[:control]      = 0x00002000

# valide for a Object message only
		@my_mask[:xml_boost_serialize]  = 0x00100000
		@my_mask[:text_boost_serialize] = 0x00200000
		@my_mask[:json_serialize]       = 0x00400000

# valid for a Status Message only  (set by SimMsgType::STATUS_REQUEST)
		@my_mask[:status_log_local]       = 0x00100000
		@my_mask[:status_log_dispatcherd] = 0x00200000
		@my_mask[:status_log_sender]      = 0x00400000

    return true
    
  end
    
end ## end of class SimMsgFlag

SimMsgFlag.new


