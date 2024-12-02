##########################################################
###
##  File: amqp_protocol.rb
##  Desc: Provides common interface to an AMQP Server (RabbitMQ)
##        for an IseRubyModel operating inside of the RubyPeer framework
##        The AMQP server is "polled" once a second for messages.
##        This library is loaded by peerrb.rb when the user has specified
##        the AMQP protocol for an IseRubyModel in the IseJCL for the IseJob.
##
##  System Environment Variables:
##
##    = Variable =    = Default =
##    AMQP_HOST       localhost
##    AMQP_USER       guest
##    AMQP_PASS       guest
##    AMQP_TYPE       topic
##    AMQP_EXCHANGE   run_guid
##    AMQP_VHOST      /
##    AMQP_LOGFILE    $ISE_ROOT/output/<guid>/<model-name>_<unit-number>_amqp.log
##    AMQP_TIMEOUT    0
##
##
##  AMQP Notes:
##
##    The topic exchange is the run_id
##    A topic key has the following form:
##      MessageClass.*.run_peer_id
##      where:
##        MessageClass is a subclass of IseMessage
##        * represents any publisher's run_peer_id
##        run_peer_id is for this IseRubyModel
##
#

puts "Entering: #{File.basename(__FILE__)}"  if $debug 

require 'debug_me'
require 'string_mods'

require 'bunny'           # GEM: wrapper around the AMQP protocol interface using event_machine

module Peerrb


  ##################################################
  ## The AMQP Protocol used by the ISE

  class AmqpProtocol
  
    ## hash key is app_message_key (the IseMessage sub-class name as a string.
    ## The value is an array of callback procs to be called in order.  This allows
    ## an application to subscribe to a message more than once with difference callback
    ## procs.
    attr_accessor :subscribed

    ## hash of the app_message table for messages subscribed and published by "this" application
    ## The hash is key'ed by app_message_key (the IseMessage sub-class name)
    ## The value is the active_record from the app_messages table
    attr_accessor :app_message

    
    
    attr_accessor :amqp_host    ## host name/ip of the AMQP server; see ENV['AMQP_HOST'] default is localhost
    attr_accessor :session      ## An AMQP session
    attr_accessor :exchange     ## An AMQP exchange
    attr_accessor :msg_queue    ## An AMQP message queue
    attr_accessor :consumer_tag ## An AMQP consumer tag used by the AMQP/Queue#subscribe method
    attr_accessor :timeout      ## How long to wait for the next message before quiting

    ####################
    def initialize( options={} )
      
      default_options = {
        :host         => ENV['AMQP_HOST'],
        :user         => ENV['AMQP_USER'],
        :pass         => ENV['AMQP_USER'],
        :type         => ENV['AMQP_TYPE'],
        :exchange     => ENV['AMQP_EXCHANGE'],
        :vhost        => ENV['AMQP_VHOST'],
        :logfile      => ENV['AMQP_LOGFILE'],
        :timeout      => ENV['AMQP_TIMEOUT'],
        :auto_delete  => true
      }
      
      amqp_options  = default_options.merge(options)
      
      
      default_logfile = $ISE_ROOT + "output" + $run_record.guid + "#{$OPTIONS[:model_name]}_#{$OPTIONS[:unit_number]}_amqp.log"
      
      @subscribed = Hash.new
      @app_message= Hash.new

      # Establish connection to the AMQP server
      
      @amqp_host      = amqp_options[:host]      || 'localhost'      
      @amqp_user      = amqp_options[:user]      || 'guest'
      @amqp_pass      = amqp_options[:pass]      || 'guest'
      @amqp_type      = amqp_options[:type]      || 'topic'
      @amqp_exchange  = amqp_options[:exchange]  || $run_record.guid
      @amqp_vhost     = amqp_options[:vhost]     || '/'
      @amqp_logfile   = amqp_options[:logfile]   || default_logfile.to_s
      @timeout        = amqp_options[:timeout]   || 0   # 0 seconds means do not timeout
      
      # TODO: rethink the AMQP_LOGFILE process; might want to set the logging parameter based upon logfile.length > 0
      
      @consumer_tag   = "#{$OPTIONS[:model_name]}-#{$OPTIONS[:unit_number]}-#{$$}"

      if $debug or $verbose
        debug_me {[
          :@amqp_host, :@amqp_vhost, :@amqp_user, :@amqp_pass, :@amqp_type, :@amqp_exchange, :@consumer_tag,
          :@amqp_logfile, :@timeout
        ]}
      end
      
      @session = Bunny.new( :user     => @amqp_user, 
                            :pass     => @amqp_pass, 
                            :host     => @amqp_host, 
                            :logging  => true, :logfile => @amqp_logfile,
                            :vhost    => '/',
                            :spec     => '09')
      begin
        @session.start
      rescue Bunny::ProtocolError
        puts "AMQP host #{amqp_host} does not support the 09 AMPQ orotocol specification; OR"
        puts "the user name and password are not known.  Both conditions produce the same exception."
        ISE::Log.error "Unable to connect to the AMQP server@#{@amqp_host} as #{@amqp_user}"
        exit(1)
      rescue Exception => e
        puts "Unable to connect to an AMQP server@#{@amqp_host} because: #{e}"
        msg = "Unable to connect to the AMQP server@#{@amqp_host} as #{@amqp_user}; suspect the server is not running."
        $stderr.puts msg
        ISE::Log.error msg
        exit(2)
      end

      # create a topic exchange
      @exchange = @session.exchange(@amqp_exchange, :type => @amqp_type.to_sym)

      # initialize the message queue for all topics sent to this run_peer_id
      @msg_queue = @session.queue(  "messages_for_#{$run_peer_record.id}",
                                    :auto_delete => amqp_options[:auto_delete]
                                 )
      
      # default key is any message from any publisher to "me"
      @msg_queue.bind(@exchange, :key => "*.*.#{$run_peer_record.id}")
      
    end  ## end of def initialize


    #####################
    # This method will be used during the
    # polling cycle to get a message from the queue and
    # dispatch it to its callback(s)
    
    def route_amqp_messages
    
      debug_me if $debug
      
      @msg_queue.subscribe( :consumer_tag => @consumer_tag,
                            :header       => true,
                            :timeout      => @timeout.to_f
      ) do |received_message|

        routing_key = received_message[:delivery_details][:routing_key]
        
        ISE::Log.debug "Received routing_key: #{routing_key}"
        
        debug_me {:routing_key} if $debug  or $debug_io
        
        
        if @subscribed.include? :all
        
          cm = @subscribed[:all][0]

          case cm.class.to_s
            when 'Method' then
              cm.call(received_message)
            when 'String' then
              eval(cm+"(received_message[:delivery_details])")
            else
              puts "INTERNAL DESIGN FLAW: callback to subscription for #{app_message_key} was not a String or a Method."
              throw RunTimeError
          end

          
        else
        
          rk_array   = routing_key.split('.')
          
          app_message_key = rk_array[0]
          message_from    = rk_array[1]
          message_to      = rk_array[2]
          
          message_class   = app_message_key.to_constant
          a_message       = message_class.new
          a_message.raw   = received_message[:payload]
          
          a_message.unpack_message(:json => true) # SMELL: Constrains all AMQP messages to be JSON encoded
          
          # TODO: consider allowing subscriber to specify wither they want to receive
          #       a self published message; something like :self => true | false
          
          callback_methods = @subscribed[app_message_key]
        
          unless callback_methods.nil?
            callback_methods.each do |cm|
              case cm.class.to_s
                when 'Method' then
                  cm.call(nil, a_message, received_message[:delivery_details])
                when 'String' then
                  eval(cm+"(nil, a_message, received_message[:delivery_details])")
                else
                  puts "INTERNAL DESIGN FLAW: callback to subscription for #{app_message_key} was not a String or a Method."
                  throw RunTimeError
              end
            end
          else
            ISE::Log.warn("Received #{routing_key} without an associated callback handler.")
          end
        
        end ## end of @subscribed[app_message_key] = [callback_method]
        
        $msg_rcvd_cnt += 1
        
      end ## end of @msg_queue.subscribe(:consumer_tag => @consumer_tag, :timeout => 30) do |msg|

      debug_me if $debug
      
      # TODO: The time out has occured so now what?  The dispatcher protocol calls fini on unbind what
      #       do we do for amqp?
      
      #Peerrb::fini
      #exit()

    end  ## end of def route_amqp_messages


    ##################################################
    ## publish_message
    
    def publish_message( a_message, options={} )

      app_message_key = a_message.class.to_s
      
      default_options = { :to           => 0,
                          :content_type => 'application/json',
                          :from         => $run_peer_record.id
      }
      
      publish_options = default_options.merge(options)
      
      unless publish_options[:routing_key]
        routing_key = "#{app_message_key}.#{publish_options[:from]}.#{publish_options[:to]}"
      else
        routing_key = publish_options[:routing_key]
      end

      debug_me {[:app_message_key, :a_message, :publish_options, :routing_key]}      if $verbose or $debug

      unless @app_message.include?(app_message_key)
        # SMELL: Does not account for a message that is not found ...
        @app_message[app_message_key] = AppMessage.find_by_app_message_key(app_message_key)
      end
      
      # SMELL: Limits AMQP messages to JSON
      a_message.pack_message(:json => true) # SMELL: May have already been done
      
      
      if $verbose or $debug
        debug_me {[:app_message_key, :peer_to_peer_id, :routing_key, :a_message, 'a_message.out']}
      end

# :key => 'routing_key' - Specifies the routing key for the message. The routing key is used 
#    for routing messages depending on the exchange configuration.
#
# :mandatory => true or false (default) - Tells the server how to react if the message cannot
#    be routed to a queue. If set to true, the server will return an unroutable message with a
#    Return method. If this flag is zero, the server silently drops the message.
#
# :immediate => true or false (default) - Tells the server how to react if the message cannot
#    be routed to a queue consumer immediately. If set to true, the server will return an 
#    undeliverable message with a Return method. If set to false, the server will queue the
#    message, but with no guarantee that it will ever be consumed.
#
# :persistent => true or false (default) - Tells the server whether to persist the message.
#    If set to true, the message will be persisted to disk and not lost if the server restarts.
#    If set to false, the message will not be persisted across server restart. Setting to true 
#    incurs a performance penalty as there is an extra cost associated with disk access.

      publish_successful = true
      begin
        @exchange.publish(  a_message.out,
                            :content_type => publish_options[:content_type],
                            :key          => routing_key, 
                            :mandatory    => false,
                            :immediate    => false,
                            :persistent   => false
                         )
      rescue Exception => e
        ISE::Log.error "AMQP publish failed routing_key: #{routing_key}  reason: #{e}"
        debug_me('AMQP publish FAILED') {[:e, :app_message_key, :routing_key, :a_message]}
        publish_successful = false
      end
      
      if publish_successful
        $msg_sent_cnt += 1
        ISE::Log.debug "AMQP published sent_cnt: #{$msg_sent_cnt}   routing_key: #{routing_key}"
      end
      
      return publish_successful
      
    end ## end of def publish_message(a_message)


    ###################################
    ## subscribe_message
    # TODO: consider allowing subscriber to specify wither they want to receive
    #       a self published message; something like :self => true | false

    def subscribe_message(message_class, callback_method=nil, options={} )
    
      debug_me if $debug
      
      app_message_key = message_class.to_s      
      
      default_options = { :to   => 0,
                          :from => '*'
                        }
      
      subscribe_options = default_options.merge(options)
      
      # NOTE: In the IseMessage#subscribe the default :from is set to zero to support
      #       legacy junk with the IseDispatcher.  Need to change it to '*' for AMQP
      subscribe_options[:from]  = '*' if 0 == subscribe_options[:from] 

      unless subscribe_options[:routing_key]
        routing_key = "#{app_message_key}.#{subscribe_options[:from]}.#{subscribe_options[:to]}"
      else
        routing_key = subscribe_options[:routing_key]
      end

      debug_me {[:app_message_key, :subscribe_options, :routing_key]}      if $verbose or $debug


      unless @app_message.include?(app_message_key)
        # FIXME: Race condition can occur when many IseModels are populating the same new messages at the same time
        begin
          app_message = AppMessage.find_by_app_message_key(app_message_key)
          raise NotFound if app_message.nil?
        rescue
          $stderr.puts "did not find #{message_key}" if $debug 
          app_message                 = AppMessage.new
          app_message.app_message_key = app_message_key
          app_message.description     = "undefined"
          begin
            app_message.save
          rescue
            $stderr.puts "did not save new #{message_key}" if $debug 
            app_message = AppMessage.find_by_app_message_key(message_key)
            raise NotFound if app_message.nil?
            $stderr.puts "accomidated race condition #{app_message_key}" if $debug 
          end
        end
      end
          
      @app_message[app_message_key] = app_message

      puts "subscribing to an IseMessage: #{app_message_key}  app_msg_id_: #{app_message.id} description: #{app_message.description}" if $debug 

      # Allow multiple subscriptions to setup a sequence of callbacks
      if @subscribed.include?(app_message_key)
        @subscribed[app_message_key] << callback_method
      else
        @subscribed[app_message_key] = [callback_method]
      end
      
      @msg_queue.bind(@exchange, :key => routing_key)
      
      pp @subscribed if $debug

      puts "leaving subscribe_message" if $debug 

    end ## end of def subscribe_message(message_name)

    #####################################
    ## Subscribe to a routing_key => '#'
    def subscribe_to_all( callback_method=nil, param_options={} )
      
      default_options = { :key => '#' }
      
      @subscribed[:all] = [callback_method]

      options = default_options.merge(param_options)
      
      @msg_queue.bind(@exchange, options)
      
      return false
    end

    
    ###################################
    ## return the subscribed hash
    def subscriptions
      return @subscribed
    end

  end ## end of class AmqpProtocol


end ## end of module Peerrb


puts "Leaving: #{File.basename(__FILE__)}"  if $debug 

