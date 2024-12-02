################################################################
###
##  File: SimpleJMessage.rb
##  Desc: A fully wrapped Link-16 message for publication
#

=begin
Link16 message(s) appear between the SimpleHeader and the SimpleFooter.

The expected order of Link16 components within the SimpleProtocol is:

  SimpleHeader
    SimpleJLink16Header
    Link16Common    <==--- provided by the base Link16Message class
    ... specific Link16 message content
  SimpleFooter

=end

require 'IseMessage'
require 'SimpleProtocol'
require 'Link16Message'
require 'string_mods'

class SimpleJMessage < IseMessage

  attr_accessor :simplej_header
  attr_accessor :simplej_link16_header
  attr_accessor :link16_message
  attr_accessor :simple_footer
  #attr_accessor :out
  def initialize(link16_message=nil)
    super()

    @max_size = 0

    @simplej_header         = SimpleJHeader.new

    @max_size += @simplej_header.max_size

    @simplej_link16_header  = SimpleJLink16Header.new

    @max_size += @simplej_link16_header.max_size

    #   @simplej_link16_header.loopback_id_ = 0xFFFF        ## DEBUG

    @simple_footer          = SimpleFooter.new

    @max_size += @simple_footer.max_size

    case link16_message.class.to_s

    # Don't know which message, just its raw binary format was provided
    when 'String' then
      @link16_message         = Link16Message.new
      @link16_message.raw     = link16_message
      @link16_message.out     = @link16_message.raw   ## Done just in case this is a pass-thru
      @link16_message.unpack_message

      # A Link16Message SubClass may have been provided
    when 'Class' then
      if 'Link16Message' == link16_message.superclass.to_s
        @link16_message         = link16_message.new
      else
        puts
        puts "ERROR: Expecting a SubClass of Link16Message."
        puts "       Got this superclass instead: #{link16_message.superclass}"
        puts
        raise RunTimeError
      end

      # An instance of a Link16Message was provided  
    else
      @link16_message         = link16_message

    end ## end of case link16_message.class.to_s

    @max_size += @link16_message.max_size

  end

  ########
  def to_s

    the_str  = "\nSimpleJ Header"
    the_str += "\n==============\n\n"
    the_str +=  @simplej_header.to_s

    the_str += "\nSimpleJ Link-16 Header"
    the_str += "\n======================\n\n"
    the_str +=  @simplej_link16_header.to_s

    the_str += "\nLink-16 Message"
    the_str += "\n===============\n\n"
    the_str +=  @link16_message.to_s

    the_str += "\nSimple Footer"
    the_str += "\n=============\n\n"
    the_str +=  @simple_footer.to_s

    return the_str

  end

  ################
  def pack_message(options={:details=>false})

    details = options[:details]

    @simplej_header.pack_message(options)          # if @simplej_header.out.empty?

    @simplej_link16_header.pack_message(options)   # if @simplej_link16_header.out.empty?
    @link16_message.pack_message(options)         # if @link16_message.out.empty?

    @out  = @simplej_header.out
    @out += @simplej_link16_header.out
    @out += @link16_message.out

    @simple_footer.checksum_ = @out.sum

    @simple_footer.pack_message
    @out += @simple_footer.out

    #puts "Packed SJH.out: #{@out.to_hex}"
    #debug_me {"@out.length"}

    return @out

  end

  ################################################
  ## NOTE: must be called in the same order as the
  ##       components were packed
  def strip_me_raw(my_component)

    raw = @raw[@pos, my_component.max_size]
    @pos += my_component.max_size

    return raw

  end

  ################
  def unpack_message(flags=0,details=false)

    @pos = 0  ## init the egg sucking

    @simplej_header.raw = strip_me_raw(@simplej_header)
    @simplej_header.unpack_message(flags,details)          # if @simplej_header.out.empty?

    @simplej_link16_header.raw = strip_me_raw(@simplej_link16_header)
    @simplej_link16_header.unpack_message(flags,details)   # if @simplej_link16_header.out.empty?

    @link16_message.raw = strip_me_raw(@link16_message)
    @link16_message.unpack_message(flags,details)          # if @link16_message.out.empty?

    @simple_footer.raw = strip_me_raw(@simple_footer)
    @simple_footer.unpack_message(flags,details)

  end

end  ## end of class SimpleJMessage
