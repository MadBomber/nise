################################################################
###
##  File: AmqpMessage.rb
##  Desc: Defines the structure of a message intended to ues the AMQP server.
##        This type of message may??? be used by stand-alone programs that
##        are not loaded by the RubyPeer.
##
##
##  NOTE: The item() method is different from the method supplied by IseMessage
##        The default serialization for AMQP messages is JSON
#

require 'IseMessage'


################################
class AmqpMessage < IseMessage

  def initialize(data=nil)
    super

    # Define common items we want in every AMQP message
    #     item name(as symbol)    default value
    item(:frame_,                 0)

  end ## end of def initialize


  ########################################################
  ## Define a message item
  def item(member_sym, item_init_value=nil)

    # Test the uniqueness of member_sym

    if self.instance_variables.include? "@#{member_sym}"

      if $verbose or $debug
        puts "\nWARNING: In message #{self.class} a message item has been redefined."
        puts "         Item name: #{member_sym}"
        ISE::Log.warn "#{member_sym} redefined in #{self.class}"
      end

      @field_uniquifier += 1
      member_sym = "#{member_sym}_#{@field_uniquifier}_".to_sym

      if $verbose or $debug
        puts "         Renamed:   #{member_sym}"
        puts
      end

    end

    @msg_items << [member_sym, nil]   # NOTE: 2nd elements is "type" which is unused by AMQP messages

    self.instance_variable_set("@#{member_sym}", item_init_value)
    self.class.send :attr_accessor, member_sym

    puts "inserted item #{member_sym} with initial value: #{item_init_value}" if $debug

  end


  #################
  def to_s
    if @raw.length > 0
      the_str  = "raw: #{@raw}\n"
      the_str += "out: #{@out}\n"
      return the_str + explode_items(true)
    else
      explode_items(true)
    end
  end


  ###########################################
  ## subscribe to a message
  # TODO: consider allowing subscriber to specify wither they want to receive
  #       a self published message; something like :self => true | false
  
  def self.subscribe(callback_method=nil, which_unit=0, router=:amqp)
  
    super
      
  end
  

  #######################
  def publish(options={})
    raise 'Not an options hash' unless 'Hash' == options.class.to_s
    default_options={:via => :amqp, :details => false, :content_type => 'application/json'}
    publish_options = default_options.merge options
    
    debug_me if publish_options[:details] or $debug
    
    super(publish_options)
  end
  

  ##################
  def unpack_message(options={})
    raise 'Not an options hash' unless 'Hash' == options.class.to_s
    default_options = {:json => true}
    unpack_options  = default_options.merge options
    super(unpack_options)
  end ## end of def unpack_message 
  

  ##############################
  def pack_message(options={})
    raise 'Not an options hash' unless 'Hash' == options.class.to_s
    default_options = {:json => true}
    pack_options  = default_options.merge options
    super(pack_options)
  end ## end of def pack_message
  

end ## end of AmqoMessage

