#####################################################################
###
##  File:  IseMessage.rb
##  Desc:  The base class for all ISE Messages.
#

if $warn_once.nil?
  $warn_once = Hash.new
else
  unless 'Hash' == $warn_once.class.to_s
    ISE::Log.error "IseMessage: the global variable $warn_once has beed defined as something other than a Hash"
  end
end



#require 'debug_me'

#require 'faster_xml_simple'
require 'xmlsimple'     # GEM: XML parser
require 'json'          # GEM: Javascrpt Object Notation

require 'IseRouter'
require 'IseDatabase'
require 'SimMsgFlag'
require 'SimMsgType'

require 'SamsonMath'
include SamsonMath

require 'string_mods'

class  IseMessage

  # An array of sub-class names that have IseMessages as a super class
  @@sub_classes = []

  # The description of a message
  attr_accessor :desc
  
  # the items that comprise the message
  attr_accessor :msg_items
  
  # the packed incoming message hot off the wire
  attr_accessor :raw
  
  # the packed outgoing message ready to be put on the wire
  attr_accessor :out
  
  # The current zero-based byte position in :raw or :out buffer
  attr_accessor :pos
  
  # The record from the app_message table that applies to this message
  attr_accessor :app_message
  
  # FIXME: Need to remove all functionality that uses @max_size
  attr_accessor :max_size
  
  # A buffer simular to :raw and :out but used in the to_xml and from_xml methods
  # to clarify functionality.
  attr_accessor :xml
  
  # Used by the to_h function to return a hash of the message elements
  attr_accessor :hash
  
  # used to fill the in a SamsonHeader
  attr_accessor :msg_flag_mask_
  attr_accessor :dest_id_

  ##############
  def initialize(data=nil)    # data is a string handled by the sub-classes after super is called
    @desc           = "Description Not Provided"
    @msg_items      = []
    @raw            = data.nil? ? "" : data
    @out            = ""
    @app_message    = nil
    @max_size       = 0     # FIXME: max_size is being deprecated
    @xml            = ""
    @hash           = {}
    @msg_flag_mask_ = 0x0
    @dest_id_       = 0
    
  end ## end of def initialize

  ###############
  def desc(a_str)
    @desc = a_str
  end
  
  ############
  def register
    # Insert message in IseDatabase if its not already there
    unless 'ControlMessage' == self.class.to_s

      # If it is not a control message, then the name is the key
      app_message_key = self.class.to_s

      begin

        @app_message = AppMessage.find_by_app_message_key(app_message_key)

        if @app_message.nil?

          unless 'SamsonHeader' == app_message_key
            @app_message = AppMessage.new
            @app_message.app_message_key  = app_message_key
            @app_message.description      = @desc
            @app_message.save
          end
        end
        
      rescue
        
        puts "Creating new AppMsg with key = #{app_message_key}" if $debug_io or $debug
        @app_message = AppMessage.new
        @app_message.app_message_key  = app_message_key
        @app_message.description      = @desc
        @app_message.save
      end

    end

  end ## end of def desc(a_str)


  ##############################
  # FIXME: Add feedback for bad values of the type_sym
  def item(type_sym, member_sym)
    member_sym = member_sym.to_sym
    type_sym   = type_sym.to_sym unless type_sym.is_a? Array
    @msg_items << [member_sym, type_sym]

    self.instance_variable_set("@#{member_sym}", nil) 
    self.class.send :attr_accessor, member_sym
    
    
    fmt_data = format_code(type_sym)
    fmt_data.each do |fmt|
      @max_size += fmt[1]               # FIXME: max_size is being deprecated
    end

  end ## end of def item


  #################
  def to_s
    if self.raw.length != @max_size     # FIXME: max_size is being deprecated
      the_str  = "raw: #{@raw}\n"
      the_str += "out: #{@out.to_hex}\n"
      return the_str += explode_items(false)
    else
      explode_items
    end
  end ## end of def to_s
  
  
  #################
  def explode_items(include_value=true)
    a_str = "#{self.class.to_s} -- #{@desc}\n"
    @msg_items.each do |mi|
      a_str += "| #{mi[0]}  -=> #{mi[1]}"
      if include_value
        a_str += "\tValue: "
        my_value = self.instance_variable_get("@#{mi[0]}")
        a_str += "#{my_value}"
        a_str += " #{my_value.class}"
        if 'Fixnum' == my_value.class.to_s
          a_str += sprintf(" (%x -=> %b)", my_value, my_value)
        end
      end
      a_str += "\n"
    end
    a_str += "="*40
    return a_str + "\n"
  end ## end of def explode_items(include_value=true)
  
  
  ##############################################################
  ## pack items into @out
  
  def pack_message(options={})
  
    raise 'Not an options hash' unless 'Hash' == options.class.to_s
  
    default_options = {:details => false, :xml => false, :json => false}
    pack_options    = default_options.merge options
    
    details = pack_options[:details]  # used as a debugging switch
    
    if pack_options[:xml]
      puts "Packing message #{self.class} as XML" if $debug_io or $debug or details
      return to_xml
    end

    if pack_options[:json]
      puts "Packing message #{self.class} as JSON" if $debug_io or $debug or details
      return to_json
    end
  
    # Do a binary packing of the message
    puts "Packing message #{self.class} as binary" if $debug_io or $debug or details
    @out = ""
    @pos = 0
    msg_size=0
    @msg_items.each do |an_item|
      puts "... packing item: #{an_item[0]} with format #{an_item[1]} into @out" if details
      
      my_value = self.instance_variable_get("@#{an_item[0]}")
      
      if details
        case an_item[0]
          when :type_ then
            the_str = SimMsgType.get_desc_(my_value)
          when :app_msg_id_ then
            if $connection.app_message[my_value]
              the_str  = $connection.app_message[my_value].app_message_key + ", "
              the_str += $connection.app_message[my_value].description
            else
              the_str = 'unknown message'
            end
          else
            the_str = ''
        end
        puts "...... my_value: #{my_value} #{the_str}"
      end
      
      fmt_data = format_code(an_item[1])
      fmt_code = ''
      fmt_size = 0
      
      fmt_data.each do |fmt|
        fmt_code << fmt[0]
        fmt_size += fmt[1]  # NOTE: fmt[1] will be zero for class-based items
      end
      
      
      begin
        if fmt_code.include?('string')
          @out << my_value.send("to_#{fmt_code}")
          fmt_size += my_value.length
        else
          @out << [my_value].flatten.pack(fmt_code)
        end
      rescue
        $stderr.puts "ERROR packing #{an_item[0]} value: #{my_value}  fmt_code: #{fmt_code}"
        $stderr.puts caller
      end
      
      msg_size += fmt_size
      
      @pos += fmt_size
      
    end ## end of @msg_items.each do |an_item|
    
    puts "msg_size: #{msg_size} bits/bytes/words/xyzzy" if details
    
    return @out
    
  end # end of def pack_message
  
  
  ##############################################################
  ## unpack items from @raw or @xml (xml over-rides raw)
  ##
  ##  flags is from the SamsonHeader (SimMsgFlags)
  #
  # TODO: change parameters to an options hash
  
  def unpack_message(options={})
    
    raise "Not an options hash: #{options.class}/#{options}" unless 'Hash' == options.class.to_s
      
    default_options = {:fkags => 0, :details => false, :xml => false, :json => false}
    unpack_options  = default_options.merge options
    
    flags   = unpack_options[:flags]
    details = unpack_options[:details]
  
    # TODO: test flags for JSON then use from_json
    
    if SimMsgFlag.test(flags, :json_serialize)  ||  unpack_options[:json]
      from_json
      return nil
    end
  
    # FIXME: really I mean it, get rid of the max_size junk
    @max_size = @raw.length # FIXME: max_size is deprecated; this is a hack to keep things working
  
    # FIXME: max_size is being deprecated
    puts "Unpacking message #{self.class}  max_size expected: #{@max_size} size rcvd: #{self.raw.length}" if $debug_io or $debug or details

    # FIXME: Need to remove all functionality that uses @max_size
    if @max_size < @raw.length
      unless SimMsgFlag.test(flags, :xml_boost_serialize)
        $stderr.puts 
        $stderr.puts "POTENTIAL SYSTEM ERROR:  #{__FILE__}  at line:  #{__LINE__}"
        $stderr.puts "    Message size mismatch."
        $stderr.puts "    Unpacking message: #{self.class}"
        $stderr.puts "    max_size expected: #{@max_size}"        # FIXME: max_size is being deprecated
        $stderr.puts "    size rcvd:         #{self.raw.length}"
        $stderr.puts "    self: #{self.inspect}"
        $stderr.puts
        $stderr.puts "Attempting recovery by treating this message as if it were XML formatted."
        $stderr.puts
        $stderr.puts
        $stderr.puts
        $stderr.puts
        from_xml
        return nil
      end 
    end

    if SimMsgFlag.test(flags, :xml_boost_serialize)  || unpack_options[:xml]
      from_xml
      return nil
    end
    
    @pos = 0    # use position to march through the incoming buffer
   
    @msg_items.each do |an_item|
      puts "... unpacking item: #{an_item[0]} with format #{an_item[1]} from @raw" if details
      
      fmt_data = format_code(an_item[1])
        # NOTE: fmt_data is an array of arrays
        #       The ONLY currently implemented Structure is position: [lat, lon, alt]
        #       All other elements in a message single data items.  The use of the new
        #       class-based pack/unpack capability is used to implement structures.
        # FIXME: revisit the position elements in existing message and develop a class that
        #        is consist for the implementation of structures.
      fmt_code = ''
      fmt_size = 0
      fmt_data.each do |fmt|
        fmt_code << fmt[0]
        fmt_size += fmt[1]
      end

      if fmt_code.include?('string')
        # extract a variable length string
        my_value = @raw[@pos,@raw.length].send("from_#{fmt_code}")
        fmt_size += my_value.length
      else
        # Standard Array#unpack of message elements
        my_value = @raw[@pos,fmt_size].unpack(fmt_code)
        my_value = my_value[0] if an_item[1].is_a? Symbol
      end
      
      @pos += fmt_size
      
      self.instance_variable_set("@#{an_item[0]}", my_value)

      if details
        case an_item[0]
          when :type_ then
            the_str = SimMsgType.get_desc_(my_value)
          when :app_msg_id_ then
            if $connection.app_message[my_value]
              the_str  = $connection.app_message[my_value].app_message_key + ", "
              the_str += $connection.app_message[my_value].description
            else
              the_str = 'unknown message'
            end
          else
            the_str = ''
        end
        puts "...... my_value: #{my_value} #{the_str}"
      end


    end
    return nil
  end # end of def unpack_message
  
  
  ##############################################################
  ## format_code will return the appropriate directive for
  ## item type specified.
=begin
 Directive    Meaning
 ---------------------------------------------------------------
     @     |  Moves to absolute position
     A     |  ASCII string (space padded, count is width)
     a     |  ASCII string (null padded, count is width)
     B     |  Bit string (descending bit order)
     b     |  Bit string (ascending bit order)
     C     |  Unsigned char
     c     |  Char
     D, d  |  Double-precision float, native format
     E     |  Double-precision float, little-endian byte order
     e     |  Single-precision float, little-endian byte order
     F, f  |  Single-precision float, native format
     G     |  Double-precision float, network (big-endian) byte order
     g     |  Single-precision float, network (big-endian) byte order
     H     |  Hex string (high nibble first)
     h     |  Hex string (low nibble first)
     I     |  Unsigned integer
     i     |  Integer
     L     |  Unsigned long
     l     |  Long
     M     |  Quoted printable, MIME encoding (see RFC2045)
     m     |  Base64 encoded string
     N     |  Long, network (big-endian) byte order
     n     |  Short, network (big-endian) byte-order
     P     |  Pointer to a structure (fixed-length string)
     p     |  Pointer to a null-terminated string
     Q, q  |  64-bit number
     S     |  Unsigned short
     s     |  Short
     U     |  UTF-8
     u     |  UU-encoded string
     V     |  Long, little-endian byte order
     v     |  Short, little-endian byte order
     w     |  BER-compressed integer\fnm
     X     |  Back up a byte
     x     |  Null byte
     Z     |  Same as ``a'', except that null is added with *
=end


  def format_code a_format
  
    rtn_array = []
    an_array  = 'Array' == a_format.class.to_s ? a_format.flatten : [a_format]
    
    an_array.each do |my_format|
      # The two element arrays below represent two 'kinds' of arrays
      # The first kind uses the standard Ruby way of extracting items from a string array
      # using the format codes documented above.  The first entry is the code.  The second
      # entry is the number of bytes that will be extracted.
      # The second kind uses ISE defined classes as the first item in the array.  The second
      # item is always zero.  The zero length is the signal that the first element is a
      # class name.
      rtn_array << case my_format
        # standard Ruby array-based
        when :unsigned_char, :UINT8  then ['C',    1]    # one character
        when :UINT8_4        then ['C4',   4]    # array of four byte
        when :ascii_string2  then ['A2',   2]    # two characters
        when :ascii_string12 then ['A12', 12]    # twelve characters
        when :ascii_string32 then ['A32', 32]    # thirty-two characters
        when :ascii_string80 then ['A80', 80]    # up to 80 characters characters (will be padded)
        when :double         then ['G',    8]    # Double-precision float, network (big-endian) byte order
        when :FLOAT          then ['g',    4]    # single-precision float, network (big-endian) byte order
        when :FLOAT_4        then ['g4',  16]    # array of 4 single-precision float, network (big-endian) byte order
        when :ACE_UINT16     then ['n',    2]    # Short, network (big-endian) byte-order
        when :ACE_INT16      then ['n',    2]    # SMELL: Short, network (big-endian) byte-order
        when :UINT16         then ['n',    2]    # Short, network (big-endian) byte-order
        when :INT16          then ['n',    2]    # SMELL: Short, network (big-endian) byte-order
        when :LITTLE_UINT16  then ['v',    2]    # Short, little-endian byte-order
        when :bool           then ['n',    2]    # FIXME: boolean (bool) not network safe
        when :ACE_UINT32     then ['N',    4]    # Long, network (big-endian) byte order
        when :ACE_INT32      then ['N',    4]    # SMELL: Long, network (big-endian) byte order
        when :UINT32         then ['N',    4]    # Long, network (big-endian) byte order
        when :INT32          then ['N',    4]    # SMELL: Long, network (big-endian) byte order
        when :bits_1         then ['B1',   1]
        when :bits_2         then ['B2',   2]
        when :bits_3         then ['B3',   3]
        when :bits_4         then ['B4',   4]
        when :bits_5         then ['B5',   5]
        when :bits_6         then ['B6',   6]
        when :bits_7         then ['B7',   7]
        when :bits_10        then ['B10', 10]
        when :bits_12        then ['B12', 12]
        when :bits_13        then ['B13', 13]
        when :bits_14        then ['B14', 14]
        when :bits_16        then ['B16', 16]
        when :bits_23        then ['B23', 23]
        
        # Variable Length String encodings
        # The fmt_code is the method to send to the String instance
        # prepend either 'to_' or 'from_' for packing and unpacking
        # The fmt_size element is in addition to the string length
        when :cstring        then ['cstring',1]   # a C-ish string with a terminating null character
        when :pstring        then ['pstring',1]   # a Pascal-ish string with a prepended length bute
        when :p2string       then ['p2string',2]  # 2-bytes prepended for length
        when :p4string       then ['p4string',4]  # 4 butes prepended for length
                
        else
          puts "ERROR: debug-else=#{my_format}  #{my_format.class}  #{my_format.inspect}"
          nil
      end
    end

#    puts "...... format_code -=> #{rtn_array.inspect}" if $debug

    return rtn_array
   
  end ## end of def format_code





  ###########################################
  ## Publish a message
  ## options hash
  ##    :via => :dispatcher | :amqp | :both
  
  def publish(options={})

    raise 'Not an options hash' unless 'Hash' == options.class.to_s

    default_options={ :via      => IseRouter::DEFAULT_ROUTER,
                      :details  => false
                    }
                    
    publish_options = default_options.merge options
  
    details = publish_options[:details]
    
    debug_me      if $debug or details
    
=begin
# TODO: change $connection into a Hash where the keys are IseRouter names
#       for example, $connection[:dispatcher], $connection[:amqp]

    routers = [publish_options[:via]].flatten
    
    routers.each do |r|
      unless $connection[r].nil?
        $connection[r].publish_message(self, publish_options)
      else
        warning_key = "#{r}-#{self.class}"
        unless $warn_once[warning_key]]
          ISE::Log.warn "IseRouter #{r} is not available for IseMessage #{self.class}"
          $warn_once[warning_key] = true
        end
      end
    end

=end

    if :dispatcher  == publish_options[:via]  ||  :both == publish_options[:via]
      $connection.publish_message(self)  unless $connection.nil?
    end
    

    if :amqp        == publish_options[:via]  ||  :both == publish_options[:via]
      $amqp_connection.publish_message(self, publish_options)  unless $amqp_connection.nil?
    end
    
    debug_me       if $debug 
  
  end
  
  
  ######################################################
  ## Put the current values of the message into the hash
  def to_h
  
    @msg_items.each do |mi|
      mi_name         = mi[0]
      @hash[mi_name]  = instance_variable_get("@#{mi_name}")
    end
    
    return @hash
  
  end ## to_h
  
  alias :to_hash :to_h

  
  ######################################################
  ## Get the current values of the message from the hash
  def from_h
  
    @hash.each_pair do |mi_name, mi_value|
      self.instance_variable_set("@#{mi_name}", mi_value)
    end
    
    return nil
  
  end ## from_h
  
  alias :from_hash :from_h
  
  
  def to_json
    to_h
    @out = JSON.generate @hash
  end

  
  def from_json
    @hash = JSON.parse @raw
    from_hash
  end


  #####################################################################
  ## Convert the message into XML compatiable with the Boost Serializer
  ## TODO: implement the to_xml method

  def to_xml
  
    puts "entered IseMessage#to_xml" if  $debug
  
    # TODO: Run through the items list putting stuff into @hash
    
    @xml = XmlSimple.xml_out @hash

    puts "leaving IseMessage#to_xml" if  $debug
      
  end ## end of to_xml
  
  
  #####################################################
  ## Message was sent as XML using the Boost Serializer
  ## Convert it into usable Ruby objects
  
  def from_xml

    puts "entered IseMessage#from_xml" if  $debug
  
    @xml  = @raw
    
    begin
#      @hash = FasterXmlSimple.xml_in(@xml)['theObj']  ## convert to hash; knockoff the outter layer
      @hash = XmlSimple.xml_in(@xml)  ##, { 'KeyAttr' => 'name' } convert to hash; the outter layer is automaticall stripped
      #debug_me() {:@hash}
    rescue
      $stderr.puts
      $stderr.puts "INTERNAL SYSTEM ERROR:"
      $stderr.puts "    Malformed XML message received."
      $stderr.puts "    Model:        #{$OPTIONS[:model_name]}"
      $stderr.puts "    Message:      #{self.class}"
      $stderr.puts "    raw as hex:   #{@raw.to_hex}"
      $stderr.puts "    raw as ascii: #{@raw}"
      $stderr.puts
      exit -1
    end
    
    @msg_items.each do |mi|
      mi_name         = mi[0]
      mi_type         = mi[1]
      the_value       = @hash[mi_name.to_s]   ## The xml values are always strings
      the_real_value  = nil                   ## the real value will as described by mi_type
      
      case mi_type
        when :double, :FLOAT then
          the_real_value = the_value[0].to_f
        when :ACE_UINT32, :ACE_INT32, :ACE_UINT16, :ACE_INT16, :bool, :UINT8 then
          the_real_value =  the_value[0].to_i
        when [:double, :double, :double]  then  ## SMELL: Assume its a SamsonMath::EulerAngles or Vec3 type
          the_real_value = []
          SamsonMath::Names.each do |sn|
            #debug_me(){[:sn, :the_value]}
            the_real_value << the_value[0][sn][0].to_f
          end
        when :unsigned_char, :ascii_string2, :ascii_string32, :cstring, :string then
          the_real_value = the_value.to_s
        else
          puts "ERROR: #{self.class} unknown type: #{mi_type} of class: #{mi_type.class}"
      end


      unless the_real_value.nil?
        self.instance_variable_set("@#{mi_name}", the_real_value)
      else
        puts "ERROR: fix type list in IseMessage#from_xml"
      end

      
    end ## end of @msg_items.each do
    

    puts "leaving IseMessage#from_xml" if  $debug
  
  end ## end of from_xml




#################################################################


  
  #################
  # Class Methods #
  #################
  
  

  ###########################################
  ## subscribe to a message
  # TODO: consider allowing subscriber to specify wither they want to receive
  #       a self published message; something like :self => true | false

  def self.subscribe(callback_method=nil, options={} )
  
    raise 'The options parameter is not a Hash' unless 'Hash' == options.class.to_s
  
    puts "Entering subscribe"  if $debug  or $debug_io
    pp self if $debug or $debug_io
    
    default_options = { :via  => IseRouter::DEFAULT_ROUTER,
                        :from => 0    ## This is default for IseDispatcher
                      }
    
    subscribe_options = default_options.merge(options)
    
    router      = subscribe_options[:via]
    which_unit  = subscribe_options[:from]
    
    $connection.subscribe_message(self,      callback_method, which_unit)  if :dispatcher == router || :both == router
    $amqp_connection.subscribe_message(self, callback_method, subscribe_options)  if :amqp == router       || :both == router
    
    puts "leaving subscribe"  if $debug  or $debug_io
  
  end


  ###########################################
  ## unsubscribe from a message
  ## TODO: Add support for IseRouter
  
  def self.unsubscribe
  
    puts "Entering unsubscribe"
    $connection.unsubscribe_message self
    puts "leaving unsubscribe"
  
  end

  ######################################################
  ## dump the message as hex; put a space between items
  
  def self.hex_dump
  
    data = @raw.length > 0 ? @raw.to_hex : @out.to_hex
    
    a_str = ''
    pos = 0
    
    @msg_items.each do |mi|
      item_name = mi[0]
      item_size = self.format_code mi[1][1] * 2
      a_str << data[pos.item_size] + ' '
      pos += item_size    
    end
    
    return a_str
  
  end ##  end of def hex_dump


  ##################################################
  ## callback invoked when a new subclass is defined
  def self.inherited(sub)
    @@sub_classes << sub
    return nil
  end
  
  ##########################################
  ## return a list of all defined subclasses
  def self.sub_classes
    return @@sub_classes
  end


end ## end of class IseMessage

