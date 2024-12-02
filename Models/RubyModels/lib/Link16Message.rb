################################################################
###
##  File: Link16Message.rb
##  Desc: Defines the structure of a Link16 Message
##        for use with Link-16 messages on the network
#

require 'IseMessage'
require 'string_mods'

$link16_common_length = 2   ## in bytes; its really only 13 bits

################################
class Link16Message < IseMessage

  @@word_size  = 16
  @@next_word  = 0
  @@msbit      = 15
  @@lsbit      = 0

  # The AirTrack and SpaceTrack use a special encoding for track_id
  @@track_id_decoder = {
    '000'   => '0',
    '001'   => '1',
    '010'   => '2',
    '011'   => '3',
    '100'   => '4',
    '101'   => '5',
    '110'   => '6',
    '111'   => '7',
    # 8 and 9 are invalid characters
    '01000' => 'A',
    '01001' => 'B',
    '01010' => 'C',
    '01011' => 'D',
    '01100' => 'E',
    '01101' => 'F',
    '01110' => 'G',
    '01111' => 'H',
    # I is an invalid character
    '10000' => 'J',
    '10001' => 'K',
    '10010' => 'L',
    '10011' => 'M',
    '10100' => 'N',
    # O is an invalid character
    '10101' => 'P',
    '10110' => 'Q',
    '10111' => 'R',
    '11000' => 'S',
    '11001' => 'T',
    '11010' => 'U',
    '11011' => 'V',
    '11100' => 'W',
    '11101' => 'X',
    '11110' => 'Y',
    '11111' => 'Z'
  }

  @@track_id_encoder = {
    '0' => '000',
    '1' => '001',
    '2' => '010',
    '3' => '011',
    '4' => '100',
    '5' => '101',
    '6' => '110',
    '7' => '111',
    # 8 and 9 are invalid characters
    'A' => '01000',
    'B' => '01001',
    'C' => '01010',
    'D' => '01011',
    'E' => '01100',
    'F' => '01101',
    'G' => '01110',
    'H' => '01111',
    'J' => '10000',
    # I is an invalid character
    'K' => '10001',
    'L' => '10010',
    'M' => '10011',
    'N' => '10100',
    # O is an invalid character
    'P' => '10101',
    'Q' => '10110',
    'R' => '10111',
    'S' => '11000',
    'T' => '11001',
    'U' => '11010',
    'V' => '11011',
    'W' => '11100',
    'X' => '11101',
    'Y' => '11110',
    'Z' => '11111'
  }

  def initialize(data=nil)
    super

    @field_uniquifier = 0   ## used to insure uniqueness of field names
    @bom_format       = ""
    @max_size_bits = 0

    #     field name         default value
    type(:word_format_,           '00')
    type(:label_j_series_,        '00011')
    type(:sublabel_j_series_,     '110')
    type(:message_len_indicator_, '010')
    
    # after these are all declared, compute max_size (which is bytes)
    @max_size = (@max_size_bits/8.0).ceil

    if data && data.class.to_s == 'String'
      @raw = data
      @out = ''
      unpack_message
    end

  end ## end of def initialize

  ########
  def item
    puts "ERROR: Link16 messages are bit-oriented, use the 'type' method to define a field."
    raise RunTimeError
  end

  ########################################################
  ## Using type to be consistent with the C++ header files
  ## used to define the bit oriented little endian 16-bit
  ## structure of the link-16 definitions
  def type(member_sym, field_example)

    # Test the uniqueness of member_sym

    if self.instance_variables.include? "@#{member_sym}"

      if $verbose or $debug
        puts "\nWARNING: In message #{self.class} a message element has been redefined."
        puts "         Item name: #{member_sym}"
      end

      @field_uniquifier += 1
      member_sym = "#{member_sym}#{@field_uniquifier}_".to_sym

      if $verbose or $debug
        puts "         Renamed:   #{member_sym}"
        puts
      end

    end

    # member_sym is a symbol
    # field_example is either a String or a Fixnum
    #   as a String - a binary rep of a default value of the exact field width: '001001110'
    #   as a Fixnum = a field width

    case field_example.class.to_s
    when 'String'
      field_example.gsub!('_', '') if field_example.count('_') > 0
      bit_field_size  = field_example.length
      default_value   = Integer('0b'+field_example)
    when 'Fixnum'
      bit_field_size  = field_example
      default_value   = 0
    else
      puts "ERROR: unknown class for field_example in #{self}#type"
      puts "       field_example: #{field_example.inspect}"
    end

    # the message items are being inserted in reverse order
    # in order to more easily pack and unpack their values
    @msg_items.insert(0, [member_sym, bit_field_size])

    self.instance_variable_set("@#{member_sym}", default_value)
    self.class.send :attr_accessor, member_sym

    @max_size_bits += bit_field_size

    puts "inserted #{member_sym} with bit field size: #{bit_field_size} and default value: #{default_value} (#{sprintf('0x%x 0b%b', default_value, default_value)})" if $debug

  end

  #################
  def to_s

    if @raw.length != @max_size
      the_str  = "max_size: #{@max_size_bits} bits #{@max_size} bytes\n"
      the_str += "raw1: (#{@raw.length} bytes) #{@raw.to_hex}\n"
      the_str += "raw2: (#{@raw.length} bytes) #{@raw.to_hex('_',5)}\n"
      the_str += "out: (#{@out.length} bytes) #{@out.to_hex}\n"
      return the_str + explode_items(false)
    else
      explode_items
    end
  end

  #################
  def explode_items(include_value=true)
    a_str = "#{self.class.to_s} -- #{@desc}\n"
    @msg_items.reverse.each do |mi|
      a_str += "| #{mi[0]}  bit field size: #{mi[1]}"
      if include_value
        a_str += "\tValue: "
        my_value = self.instance_variable_get("@#{mi[0]}")
        a_str += "#{my_value}"
        a_str += " (#{sprintf('0x%x  0b%b', my_value, my_value)})"
      end
      a_str += "\n"
    end
    a_str += "="*40
    return a_str + "\n"
  end

  ##################
  def unpack_message(options={:flags=>0,:details=>false})
  
    flags   = options[:flags]
    details = options[:details]

    bit_stream = @raw.reverse(2).swap_bytes.to_binary

    if details or $debug
      puts "raw:              #{@raw.to_hex}"
      puts "raw reversed(2):  #{@raw.reverse(2).to_hex}"
      puts "rr2 byte swapped: #{@raw.reverse(2).swap_bytes.to_hex}"
      puts "bit_stream:       #{bit_stream}"
    end

    bit_offset = 0

    @msg_items.each do |mi|
      member_sym      = mi[0]
      bit_field_size  = mi[1]

      puts "unpacking #{bit_field_size} bits for #{member_sym} ..." if details or $debug

      value_binary = "0b" + bit_stream[bit_offset, bit_field_size]

      if bit_field_size <= 32
        value        = Integer(value_binary)
      else
        value        = value_binary
      end

      puts "... #{member_sym} at bit_offset: #{bit_offset} has value: #{value_binary} (#{value} #{sprintf('0x%x', value)})" if details or $debug
      self.instance_variable_set("@#{member_sym}", value)
      bit_offset += bit_field_size

    end

  end ## end of def unpack_message

  ##############################
  def pack_message(options={:details=>false})

    details = options[:details]
    
    puts "Packing message #{self.class}" if $debug_io or $debug or details

    out_bits  = ""
    msg_size  = 0

    @msg_items.each do |an_item|

      my_name   = an_item[0]
      my_value  = self.instance_variable_get("@#{my_name}")
      my_size   = an_item[1]   ## bit field size
      my_bits   = ("0"*64 + my_value.to_s(2))[-my_size, my_size]

      if details
        puts "... packing #{my_name} my_value: #{my_value} as #{my_size} bits: #{my_bits}"
      end

      msg_size += my_size                 ## message size in bits

      out_bits << my_bits

    end ## end of @msg_items.each do |an_item|

    if details
      puts "DEBUG: msg_size matches: #{msg_size} == #{out_bits.length} "
    end

    @raw = ""

    # FIXME: Get a faster process
    out_bits.scan(/......../) do |a_byte|
      @raw << Integer("0b"+a_byte).chr
    end

    @out = @raw.reverse(2).byte_swap

    puts "DEBUG: length of @out: #{@out.length}"    if details

    return @out

  end ## end of def pack_message

  ##############################################
  def self.encode_track_id(prefix_in, unit_id_in=nil)

    if unit_id_in
      case unit_id_in.class.to_s
      when 'Fixnum' then
        unit_id = unit_id_in.to_s
      when 'String' then
        unit_id = unit_id_in
      else
        raise 'Expecting unit_id_in to be either Fixnum or String.'
      end
      unit_id = "0" + unit_id while 3 > unit_id.length
    end

    raise 'Expecting prefix_in to be of String type.' unless 'String' == prefix_in.class.to_s

    if unit_id_in.nil? 
      unless 5 == prefix_in.length
        $stderr.puts ">"*45
        $stderr.puts "Link16Message#encode_track_id =[#{prefix_in}]= len: #{prefix_in.length}"
        $stderr.puts "<"*45
        raise 'prefix_in length should be 5'
      end

    end

    if unit_id_in and 2 != prefix_in.length
      $stderr.puts ">"*45
      $stderr.puts "DEBUG: length of \"#{unit_id_in}\" is #{prefix_in.length}"
      $stderr.puts "<"*45
      raise 'prefix_in length should be 2'       
    end

    if unit_id_in
      track_id = prefix_in + unit_id
    else
      track_id = prefix_in
    end

    track_id_out = '0b'

    track_id.upcase!

    track_id.each_char do |c|

      case c
      when '8' then raise "Invalid character (8) detected in track_id"
      when '9' then raise "Invalid character (9) detected in track_id"
      when 'I' then raise "Invalid character (I-eye) detected in track_id"
      when 'O' then raise "Invalid character (O-oh) detected in track_id"
      end

      track_id_out << @@track_id_encoder[c]

    end

    return Integer(track_id_out)

  end ## end of def encode_track_id

  ################################
  def self.decode_track_id(track_id_in)

    case track_id_in.class.to_s
    when 'String' then
      track_id = track_id_in.strip.downcase
      track_id.delete!('_')
      track_id = track_id[2,track_id.length-2] if '0b' == track_id[0,2]
    when 'Fixnum' then
      track_id = track_id_in.to_s(2)
    else
      raise 'Expecting track_id_in to be either a String or a Fixnum.'
    end

    raise 'Invalid track_id' if 19 < track_id.length

    track_id = '0' + track_id while 19 > track_id.length

    track_id_out = ''

    track_id_out << @@track_id_decoder[track_id[ 0,5]]
    track_id_out << @@track_id_decoder[track_id[ 5,5]]
    track_id_out << @@track_id_decoder[track_id[10,3]]
    track_id_out << @@track_id_decoder[track_id[13,3]]
    track_id_out << @@track_id_decoder[track_id[16,3]]

    return track_id_out

  end ## end of def decode_track_id

end ## end of Link16Message

