##########################################################
###
##  File: dispatcher_protocol.rb
##  Desc: Process the command line
#

puts "Entering: #{File.basename(__FILE__)}"  if $debug 

require 'debug_me'
require 'zlib'
require 'SamsonHeader'
require 'ControlMessages'

$send_count = 0

module Peerrb


  ##################################################
  ## The ISE Protocol used by the IseDispatcher

  class IseProtocol < EventMachine::Connection

    attr_accessor :header       ## a SamsonHeader of the most recently received message
    attr_accessor :out_msg      ## outgoing message queue of all sent messages header + data
    attr_accessor :subscribed   ## hash of subscribed messages and callback_procs
    attr_accessor :run_message  ## hash of the run_message records used to fill in the SH.msg_id_ field
    attr_accessor :app_message  ## hash of the app_message table for messages subscribed
    attr_accessor :left_overs   ## The first part of a longer data packet

=begin
    state_machine :initial => :waiting_for_hello do

      event :received_hello do
        transition :waiting_for_hello => :send_hello
      end

      event :sent_hello do
        # send_hello_back
      end

    end
=end



    ####################
    def initialize *args

      debug_me if $debug
      
      super # will call post_init
      
      @header     = nil
      @msg_queue  = []
      @out_msg    = []
      @subscribed = Hash.new
      @run_message= Hash.new
      @app_message= Hash.new
      @left_overs = ''
      
    end  ## end of def initialize


    #############
    def post_init

      debug_me if $debug 
      
    end  ## end of def post_init


    ########################
    def connection_completed
    
      debug_me if $debug 
      
      $connected_to_dispatcher = true

      subscribe_special :HELLO,           method(:send_hello_back)
      subscribe_special :GOODBYE_REQUEST, method(:send_goodbye)

=begin      
      Peerrb::init
      
      if Peerrb::model_ready?
        Peerrb::model_ready!
      else
        $stderr.puts "\nIseRubyModel is not ready; shutting it down ..."
        $stderr.puts "Did you forget 'Peerrb.model_ready' at the end of your 'init' method?"
        unbind
      end
=end
      
    end


    #####################
    def receive_data data

      debug_me {"data.to_hex"} if $debug  or $debug_io
      
      if @left_overs.length > 0
        data = @left_overs + data
        @left_overs = ''
      end
      
      first_message = @msg_queue.length
      
      debug_me {[:first_message, "data.length"]} if $debug or $debug_io
      
      while data.length > 0

      
        if data.length < $samson_header_length
          @left_overs = data
          data = ''
          break
        end

      
        # SMELL: Don't like expose the SamsonHeader.magic_ constante outside the class
        if data[0,2] == 'SN'    ## Is it a SamsonHeader?

          @header = SamsonHeader.new data[0,$samson_header_length]
          total_message_length = $samson_header_length + @header.message_length_
          
          debug_me("Received Header: #{@header.msg_id_}-#{@header.app_msg_id_}") if $verbose or $debug
          
          if total_message_length > data.length
            @left_overs = data
            data = ''
            break
=begin
            puts "\n\nINTERNAL DESIGN FLAW: have not received complete message yet."
            puts "Was expecting event_machine to handle this."
            puts "data: #{data.to_hex}"
            puts "Message Queue has #{@msg_queue.length} items:"
            @msg_queue.each do |mq|
              puts "#{mq[0]}\t#{mq[1].to_hex}"
            end
            throw RunTimeError
=end
          end
          
          
          # FIXME: add @header to the @msg_queue object so we don't have to reparse it later
          @msg_queue << [Time.now.to_f, data[0,total_message_length]]
          puts "#{Time.now.to_f} I quequed this: #{data[0,total_message_length].to_hex}" if $debug 
          
          if total_message_length == data.length
            data = ''
          else
            data = data[total_message_length, data.length]
          end
        
        else
        
          $stderr.puts "\n\nInternal ERROR: expecting a SamsonHeader; did not get one."
          $stderr.puts "data: #{data.to_hex}"
          $stderr.puts

          # FIXME: Be smarter; scan forward looking for what might be the beginning of a header
          exit -1
        
        end
      
      end ## end of while data.length > 0
      
      
      # SMELL: This assumes there is no particial messages in the data received
      last_message = @msg_queue.length - 1
      
      return nil if last_message < first_message  ## nothing was queued this cycle
      
      
      puts "last_message: #{last_message}" if $debug or $debug_io
      
      message_count = last_message - first_message + 1
      
      puts "="*15 + " message_count #{message_count}" if $debug or $debug_io


      # Do this for each message just received
      
      message_count.times do |msg_inx|
      
        puts "first_message: #{first_message}   msg_inx: #{msg_inx}" if $debug or $debug_io
        
        msg_queue_index = first_message + msg_inx
      
        msg_array = @msg_queue[msg_queue_index] ## pop a message [0] is the time stamp [1] is raw
        @msg_queue[msg_queue_index] = nil       ## removes message from queue
        
        puts "working this message: #{msg_array[0]}\t#{msg_array[1].to_hex}" if $debug or $debug_io 
        
        data = msg_array[1]
        
        @header = SamsonHeader.new data
      
        case @header.type_
          when SimMsgType.type_(:DATA) then
            debug_me("received a data message") if $debug
          when SimMsgType.type_(:HELLO) then
            debug_me('received hello message') if $debug 
          when SimMsgType.type_(:GOODBYE) then
            debug_me('received goodbye message') if $debug 
            # Peerrb.fini
            # Peerrb.really_fini
          when SimMsgType.type_(:GOODBYE_REQUEST) then
            debug_me('received goodbye_request message') if $debug 
          ########################################################
          ## FIXME: Kludge; skizoid control_message / data_message
          ## SMELL: type_ and app_msg_id_ are getting confused
          when 0 then
            @header.type_ = SimMsgType.type_(:DATA)   ## convert a control_message into a data_message
            debug_me('received start_frame message') if $debug
          when SimMsgType.type_(:START_FRAME) then
            @header.type_ = SimMsgType.type_(:DATA)   ## convert a control_message into a data_message
            debug_me('received start_frame message')
          when SimMsgType.type_(:ADVANCE_TIME_REQUEST) then
            @header.type_ = SimMsgType.type_(:DATA)   ## convert a control_message into a data_message
            debug_me('received start_frame message') if $debug
          ################################################################
          when SimMsgType.type_(:STATUS_REQUEST) then
            debug_me('received status request') if $debug 
            Peerrb.info
          when SimMsgType.type_(:END_CASE) then
            debug_me('received end case') if $debug 
          when SimMsgType.type_(:END_SIMULATION) then
            debug_me('received end simulation') if $debug 
          when SimMsgType.type_(:CONTROL) then
            debug_me("received control message app_msg_id_: #{@header.app_msg_id_}") if $debug 

          ######################################################
          ## Got something that is not handled
          else
            puts "received something that is not currently handled type_  -=> #{@header.type_}"
            puts @header
        end ## end of case @header.type_
        
        
        cm_key = 0 == @header.app_msg_id_ ? "#{@header.type_}-#{@header.app_msg_id_}" : "#{@header.app_msg_id_}"

        # FIXME: Assumes only 1 subscription per message
        callback_method = @subscribed[cm_key]
        
        unless callback_method.nil?
          if 0 == @header.app_msg_id_
            a_message     = nil
          else
            # FIXME: cache the app_messages table; reference the cache instead of the RDBMS
            app_message   = AppMessage.find(@header.app_msg_id_)
            begin
              a_message     = eval(app_message.app_message_key + ".new")
            rescue
              $stderr.puts
              $stderr.puts "INTERNAL SYSTEM ERROR: Received message without subscription."
              $stderr.puts "    Model:            #{$OPTIONS[:model_name]}"
              $stderr.puts "    Message Received: #{app_message.app_message_key}"
              $stderr.puts "    Header: #{@header}"
              $stderr.puts
              $stderr.puts
              exit -1            
            end
            a_message.raw = data[$samson_header_length, @header.message_length_]
            a_message.unpack_message(:flags => @header.flags_)
          end
          case callback_method.class.to_s
            when 'Method' then
              callback_method.call(@header, a_message)
            when 'String' then
              eval(callback_method+"(@header, a_message)")
            else
              puts "INTERNAL DESIGN FLAW: callback to subscription was not a String or a Method."
              throw RunTimeError
          end ## end of case callback_method.class.to_s
        else
          puts "ERROR: This message has no associated callback registered: #{@header.type_}-#{@header.app_msg_id_}"
          puts @header
        end ## end of unless callback_method.nil?
      
        $msg_rcvd_cnt += 1
      
      end ## end of message_count.times do |msg_inx|
      
      @msg_queue = @msg_queue.compact   ## removes all nil objects from msg_queue

  # debug_me($OPTIONS[:model_name]) { [:$msg_rcvd_cnt, :$msg_sent_cnt, :$send_count, "@out_msg.length"] }

      puts "Leaving receive_data" if $debug  or $debug_io

    end  ## end of def receive_data data




    ###########################################################
    ## over-ride event_machine's send_data method to get
    ## some debuggin hooks in place
    
    def send_data data
      super
      puts "I sent this: #{data.to_hex}" if $debug_io or $debug
      $msg_sent_cnt += 1
    end





    #########################################################
    ## executed after the connection has already been dropped
    def unbind
      puts "unbind" if $debug 
      EM.stop
      #Peerrb.fini
      #Peerrb.really_fini
    end  ## end of def unbind


    ################################################
    def send_hello_back(a_header=nil, a_message=nil)
      puts "send_hello_back" if $debug 
        a_header = $control_message[:HELLO]
        a_header.pack_message     ## SMELL: may not be needed
        send_message a_header.out
      puts "hello_sent" if $debug 
    end


    #############################################
    def send_goodbye(a_header=nil, a_message=nil)
      puts "send_goodbye" if $debug 
        a_header = $control_message[:GOODBYE]
        a_header.pack_message   ## SMELL: may not be necessary
        send_data a_header.out
      puts "goodbye_sent" if $debug 
    end



    ########################
    def send_goodbye_request
      puts "send_goodbye_request" if $debug 
        a_header = $control_message[:GOODBYE_REQUEST]
        a_header.pack_message     ## may not be neccessary
        send_data a_header.out
      puts "goodbye_request_sent" if $debug 
    end


    ###################################################
    ## sent or queue a message
    
    def send_message out_data
      puts "send_message: #{out_data.to_hex}" if $debug
      send_data out_data
      @out_msg << [Time.now.to_f, out_data] if $debug
    end

    ##################################################
    ## publish_message
    
    def publish_message(a_message)
    
      app_message_key = a_message.class.to_s
      
      puts "#{Time.now.to_f} Publishing #{app_message_key}" if $verbose or $debug
      
      unless $app_message_cache.include?(app_message_key)
        $app_message_cache[app_message_key] = AppMessage.find_by_app_message_key(app_message_key)
      end
      
      app_message_id = $app_message_cache[app_message_key].id

            
      a_message.pack_message
      
      a_header                  = $control_message[:DATA].dup   # SMELL: had to ensure that new memory is allocated or bad things happen when message with the msg_flag_mask
      a_header.frame_count_     = defined?($sim_time) ? $sim_time.now : 0
      
      # JKL: setting the header flag
      a_header.flags_           |= a_message.msg_flag_mask_
      a_header.dest_peer_id_    = a_message.dest_id_
      
      $send_count += 1
      a_header.send_count_     = $send_count
      
      a_header.message_length_  = a_message.out.length
      
      
      a_header.message_crc32_   = Zlib.crc32(a_message.out)
      
      
      app_msg_id_ = app_message_id
      arm         = @run_message[app_msg_id_]
      
      # TODO: All this stuff with run_message goes away in the bleeding_edge
      
      unless arm
 
        begin
          arm = RunMessage.find($run_record.id, app_msg_id_)
        rescue
          arm = RunMessage.new
          arm.app_message_id = app_msg_id_
          arm.run_id         = $run_record.id
          arm.ref_count      = 0
          begin
            arm.save
          rescue
            # race condition have occured
            # run_messages has gone away in the bleeding_edge, yea!!
          end
          # do the find again to fill in the 'id' field
          arm = RunMessage.find($run_record.id, app_msg_id_) unless arm['id']
        end
        
        @run_message[app_msg_id_] = arm

      end

      msg_id_ = arm['id']
      
      a_header.msg_id_        = msg_id_
      a_header.app_msg_id_    = app_msg_id_
      a_header.pack_message
      
      send_message(a_header.out + a_message.out)

    end ## end of def publish_message(a_message)



    #########################################################
    ## Used to subscribe to special control messages which do
    ## not show up in the run_messages and run_scribers tables
    
    def subscribe_special(message_class, callback_method=nil)

      puts "entering subscribe_special" if $debug      
      
      message_key = message_class.to_s
      
      if 'Symbol' == message_class.class.to_s    # Means its a control (data-less) message
      
        msg_type_   = SimMsgType.type_(message_class)
        desc_       = SimMsgType.desc_(message_class)
        msg_id_     = 0
        app_msg_id_ = 0
        
        run_message = nil
        
        puts "subscribing to a control (data-less) message: #{message_key}  type_: #{msg_type_}  desc_: #{desc_}" if $debug 

        @subscribed["#{msg_type_}-#{app_msg_id_}"] = callback_method

      else
        $stderr.puts "Internal ERROR: subscribe_special not of class Symbol."
      end

      pp @subscribed if $debug

      puts "leaving subscribe_special" if $debug      

    end ## end of def subscribe_special




    ###################################
    ## subscribe_message
    def subscribe_message(message_class, callback_method=nil, from_which_unit=0)
    
      puts "entering subscribe_message" if $debug      
      
      message_key = message_class.to_s
      
      if 'Symbol' == message_class.class.to_s    # Means its a control (data-less) message
      
        msg_type_   = SimMsgType.type_(message_class)
        desc_       = SimMsgType.desc_(message_class)
        msg_id_     = 0
        app_msg_id_ = 0
        
        run_message = nil
        
        puts "subscribing to a control (data-less) message: #{message_key}  type_: #{msg_type_}  desc_: #{desc_}" if $debug 
      
      else
      
        msg_type_   = SimMsgType.type_(:DATA)


        # FIXME: Race condition can occur when many IseModels are populating the same new messages at the same time
        begin
          app_message = AppMessage.find_by_app_message_key(message_key)
          raise NotFound if app_message.nil?
        rescue
          $stderr.puts "did not find #{message_key}" if $debug 
          app_message                 = AppMessage.new
          app_message.app_message_key = message_key
          app_message.description     = "undefined"
          begin
            app_message.save
          rescue
            $stderr.puts "did not save new #{message_key}" if $debug 
            app_message = AppMessage.find_by_app_message_key(message_key)
            raise NotFound if app_message.nil?
            $stderr.puts "accomidated race condition #{message_key}" if $debug 
          end
        end

              
        # FIXME: Race condition can occur when many IseModels are populating the same new messages at the same time
        begin
          run_message = RunMessage.find([$run_record.id, app_message.id])
          raise NotFound if run_message.nil?
          run_message.ref_count      += 1
        rescue
          $stderr.puts "did not find in run_message #{[$run_record.id, app_message.id]}" if $debug 
          run_message = RunMessage.new
          run_message.run_id         = $run_record.id
          run_message.app_message_id = app_message.id
          run_message.ref_count      = 1
        end
        
        begin
          run_message.save        
        rescue
            $stderr.puts "did not save in run_message #{[$run_record.id, app_message.id]}" if $debug 
        end
        
        run_message = RunMessage.find($run_record.id, app_message.id) unless run_message['id']


        unless run_message['id']
        
          $stderr.puts
          $stderr.puts "Internal ERROR: run_message['id'] is not valid."
          $stderr.puts
          $stderr.puts
        
        end 

        @run_message[app_message.id] = run_message
        @app_message[app_message.id] = app_message

                
        # FIXME: Assumes only 1 subscription per message
        ars = RunSubscriber.new
        ars.run_message_id  = run_message['id']
        ars.run_peer_id     = $run_peer_record.id
        ars.instance        = 0
        ars.save

        puts "subscribing to an IseMessage: #{message_key}  app_msg_id_: #{app_message.id} description: #{app_message.description}" if $debug 
      
      end ## if 'ControlMessage' == message_key


      if run_message
        a_header                  = $control_message[:SUBSCRIBE]
        a_header.run_id_          = $run_record.id
        a_header.peer_id_         = $run_peer_record.id
        a_header.unit_id_         = from_which_unit   # value zero means all units
        a_header.message_length_  = 0
        a_header.msg_id_          = run_message['id']
        a_header.app_msg_id_      = app_message.id
        a_header.pack_message
        
#        send_message a_header.out
      end
      
      # FIXME: Allows only 1 subscription per message
      if app_message and 0 == app_message.id
        @subscribed["#{msg_type_}-#{app_message.id}"] = callback_method
      else
        @subscribed["#{app_message.id}"] = callback_method      ## don't care what the type_ is
      end
      
      pp @subscribed if $debug

      puts "leaving subscribe_message" if $debug 

    end ## end of def subscribe_message(message_name)

    ##################################
    ## get_next_message
    def get_next_message(message_name)

    end ## end of def get_next_message(message_name)
    
    ###################################
    ## return the subscribed hash
    def subscriptions
      return @subscribed
    end

  end ## end of class IseProtocol


end ## end of module Peerrb


#########################################################






puts "Leaving: #{File.basename(__FILE__)}"  if $debug 

