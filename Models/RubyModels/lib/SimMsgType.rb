#####################################################
###
##  File:  SimMsgType.rb
##  Desc:  Must be kept in sync with Common/SimMsgType.h
#

class SimMsgType

  class InvalidSimMsgTypeError < RuntimeError; end
  
  @@my_instance = nil
  attr_reader :my_hash
  attr_reader :my_inverted_array
  attr_reader :my_min, :my_max
  
  ##############
  def initialize
    self.new
  end

  ###########################
  def self.which_(an_integer)
  
    real_integer = an_integer.to_i
    
    raise InvalidSimMsgTypeError if @my_inverted_array[real_integer].nil? || real_number < 0
    
    return @my_inverted_array[real_integer]

  end

  #####################
  def self.type_(a_sym)
    return @my_hash[a_sym][0]
  end
  
  #####################
  def self.desc_(a_sym)
    return @my_hash[a_sym][1]  
  end
  
  
  def self.get_desc_(a_number)
    if a_number < @my_min || a_number > @my_max
      "outside bounds: #{@my_min} to #{@my_max}"
    else
      "#{@my_inverted_array[a_number].join(', ')}"
    end
  end
  
  ########################
  def self.to_s(a_sym=nil)
    return "#{a_sym}\t#{type_(a_sym)}\t#{desc_(a_sym)}" if a_sym
    rtn_str = ""
    @my_hash.each do |s, v|
      rtn_str << "#{s}\t#{v[0]}\t#{v[1]}\n"
    end
    return rtn_str
  end

##########################################################
private

  def self.new
  
    return @@my_instance if @@my_instance
    
    @@my_instance = self
    
    @my_min = 9999
    @my_max = -9999
  
    @my_hash          = Hash.new
    @my_inverted_array = []
    
    @my_hash[:UNKNOWN]                           = [-1, "There is no type for a DataCount header"]
    @my_hash[:ROUTE]                             = [0, "A normal event, which is forwarded to the <Consumers>. (not currently used)"]
    @my_hash[:SUBSCRIBE]                         = [1, "A subscription to <Suppliers> managed by the <Event_Channel>. (not currently used)"]
    @my_hash[:DATA]                              = [2, "This is data message. See SimMsgFlag for subtyping."]
    @my_hash[:RECOVERABLE_ERROR_STATUS_RESPONSE] = [3, "Error has occurred"]
    @my_hash[:FATAL_ERROR_STATUS_RESPONSE]       = [4, "Error has occurred"]
    @my_hash[:OK_STATUS_RESPONSE]                = [5, "OK"]
    @my_hash[:STATUS_REQUEST]                    = [6, "Request for status"]
    @my_hash[:XML_COMMAND]                       = [7, "The data that follows is and XML command to be parsed."]
    @my_hash[:START_FRAME]                       = [8, "Start of a time tick simulation frame,  is both a Request/Response"]
    @my_hash[:END_FRAME_REQUEST]                 = [9, "End of a frame Request"]
    @my_hash[:END_FRAME_OK_RESPONSE]             = [10, "End of frame Response"]
    @my_hash[:END_FRAME_ERROR_RESPONSE]          = [11, "End of frames Reponse:  more work to do"]
    @my_hash[:END_FRAME_COMMAND]                 = [12, "End of Frame,  any error must be a terminal error:  FATAL_ERROR_STATUS_RESPONSE"]
    @my_hash[:START_SIMULATION]                  = [13, "Used to start the simulation"]
    @my_hash[:END_SIMULATION]                    = [14, "Used to stop the simulation (END_SIMULATION)"]
    @my_hash[:START_CASE]                        = [15, "Used to start a Monte-Carlo case (START_CASE)"]
    @my_hash[:END_CASE]                          = [16, "Used to stop a Monte-Carlo case (END_CASE)"]
    @my_hash[:BREAKWIRE]                         = [17, "Used to transmit a breakwire event (start of missile flight)"]
    @my_hash[:IGNITION]                          = [18, "(NOT USED) Used to indicate Rocket Motor Ignition"]
    @my_hash[:INVOKE_REQUEST]                    = [19, "A DCE-CORBA like request to invoke a procecure.  (Future)"]
    @my_hash[:INVOKE_RESPONSE]                   = [20, "A DCE-CORBA like response to a previous request. (Future)"]
    @my_hash[:LOCATE_REQUEST]                    = [21, "A DCE-CORBA like request to perform an location lookup.  (Future)"]
    @my_hash[:LOCATE_RESPONSE]                   = [22, "A DCE-CORBA like response to a previous location lookup request. (Future)"]
    @my_hash[:HELLO]                             = [23, "A channel has come alive (HELLO)"]
    @my_hash[:INIT]                              = [24, "Used to initialize (INIT)"]
    @my_hash[:GOODBYE]                           = [25, "Shutting down this connection (GOODBYE)"]
    @my_hash[:D2D_CONNECT]                       = [26, "Temporary? used by dispatcher to connect to all other dispatchers"]
    @my_hash[:GOODBYE_REQUEST]                   = [27, "Request a process to terminate, should result in a GOODBYE response "]
    @my_hash[:DISPATCHER_COMMAND]                = [28, "Request a process to terminate, should result in a GOODBYE response "]
    @my_hash[:LOG_CHANNEL_STATUS]                = [29, "Log the Connection Handler Status (currently list saved messages)"]
    @my_hash[:ADVANCE_TIME_REQUEST]              = [30, "Pre-fire in Ptolemy II parlance, this is used to advance the clock one tick"]
    @my_hash[:TIME_ADVANCED]                     = [31, "Response to the Advance Time Request.  (Error response is not yet defined)"]
    @my_hash[:CONTROL]                           = [32, "Framework Control message.  Data may or may not be attached"]    
    @my_hash[:LOG_EVENT_CHANNEL_STATUS]          = [33, "Log the current EventChannel Status"]    

    
    @my_hash.each do |s, v|
      @my_inverted_array[v[0]] = [s, v[1]] unless v[0] < 0
      @my_min = v[0] if v[0] < @my_min
      @my_max = v[0] if v[0] > @my_max
    end

    return true
    
  end
    
end ## end of class SimMsgType

##############################################################
## Initialize the  singleton class

SimMsgType.new


