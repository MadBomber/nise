#####################################################################
###
##  File:  string_mods.rb
##  Desc:  Modifications to the String class.
#

require 'facets/string'
require 'colored'

class String

  alias :old_reverse :reverse
  
  ################################################################
  ## Presents each character of a string as a character to a block

  def each_char
    if block_given?
      scan(/./m) do |x|
        yield x
      end
    else
      scan(/./m)
    end
  end

  ######################################################
  ## Return the string as a string of hexidecimal digits
  def to_hex(word_marker=nil, word_group_count=nil)
    s = self.unpack("H2048")[0]
    word_size = 4 ## characters

    if word_marker
#      puts "-----------============>"
#      puts "s: #{s}"
#      puts "-----------============<".reverse
      s2=''
      (0..s.length-1).step(4) do |x|
        s2 += s[x,4] + word_marker
      end
      s = s2
      word_size = 5 ## characters
    end

    if word_group_count
      step_size = word_size * word_group_count
#      puts "-----------============>"
#      puts "step_size: #{step_size} = #{word_size} * #{word_group_count}"
#      puts "s: #{s}"
      s2=''
      (0..s.length-1).step(step_size) do |x|
#        puts "x: #{x}"
        s2 += s[x,step_size] + "\n"
      end
#      puts "-----------============<".reverse
      s = s2
    end
    
    return s
  end
  
  #################################################
  ## Return the string as a string of binary digits
  def to_binary(nibble_marker=nil)
    s = self.unpack('B4096')[0]
    if nibble_marker
      s2=''
      (0..s.length-1).step(4) do |x|
        s2 += s[x,4] + nibble_marker
      end
      return s2
    else
      return s
    end
  end


  ###########################################################################################
  ## TODO: check input string to make sure that its only hex digits, periods, and underscores
  ## TODO: remove periods and underscores from input string before conversion.
  ## TODO: make sure length of string is even.
  def to_characters

    x = self.length
    
    s=''
    (0..x-1).step(2) do |inx|
      cv = '0x' + self[inx,2]
      v = cv.hex
      c = v.chr
      s += c
    end
    
    return s

  end ## end of def to_characters(hex_data_str)


  ##########################################
  ## FIXME: make sure length of input is even
  def swap_bytes

    x = self.length
    
    s=''
    (0..x-1).step(2) do |inx|
      s << self[inx+1]
      s << self[inx]
    end
    
    return s

  end ## end of def swap_bytes(a_str)

  alias :byte_swap :swap_bytes
  
  #################################################################################
  def reverse(count=1)
  
    if 1 == count
      self.old_reverse
    else
      x=self.length
      s=''
      (0..x-1).step(count) do |inx|
        s.insert(0,self[inx,count])
      end
      return s
    end
  
  end



  ##################################
  ## Convert CamelCase to camel_case
  def to_underscore
    self.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end  

  alias :to_snakecase :to_underscore
  alias :underscore   :to_underscore

  ##################################
  ## Convert camel_case to CamelCase
  def to_camelcase
    self.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end

  alias :camelize :to_camelcase


  ##################################
  ## Convert "CamelCase" into CamelCase
  def to_constant
    names = self.split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      if '1.9' == RUBY_VERSION[0,3]
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      else
        constant = constant.const_get(name) || constant.const_missing(name)
      end
    end
    constant
  end
  
  alias :constantize :to_constant

  ##################################
  ## Support for C-ish strings
  def to_cstring
    self + "\000"
  end
  
  def from_cstring
    x = self.index("\000")
    x > 0 ? self[0,x] : ''
  end

  ##################################
  ## Support for Pascal-ish strings
  ## using 1 byte prepended as length
  def to_pstring
    raise 'StringTooLong' if self.length > 255 # 2**8 - 1
    [self.length].pack('C1') + self
  end
  
  def from_pstring
    x = self.unpack('C')[0]
    self[1,x]
  end

  
  ##################################
  ## Support for Pascal-ish strings
  ## using 2 bytes prepended as length
  ## length is in big-endian, network order
  ## UINT16
  def to_p2string
    raise 'StringTooLong' if self.length > 65_535 # 2**16 - 1
    [self.length].pack('n') + self
  end
  
  def from_p2string
    x = self.unpack('n')[0]
    self[2,x]
  end

  
  ##################################
  ## Support for Pascal-ish strings
  ## using 4 bytes prepended as length
  ## length is in big-endian, network order
  ## UINT32
  def to_p4string
    raise 'StringTooLong' if self.length > 4_294_967_295 # 2**32 - 1
    [self.length].pack('N') + self
  end
  
  def from_p4string
    x = self.unpack('N')[0]
    self[4,x]
  end

end ## end of class String


