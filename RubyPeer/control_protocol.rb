##########################################################
###
##  File: control_protocol.rb
##  Desc: man-in-the-loop control protocol for the RubyPeer
#

# TODO: Need generic plugin-like way to dynamicall setup control commands for peerrb and IseRubyModels

puts "Entering: #{File.basename(__FILE__)}"  if $debug or $verbose


module Peerrb


  ##################################################
  ## The ISE Protocol used by the IseDispatcher

  class ControlProtocol < EventMachine::Connection

    ####################
    def initialize *args
      super # will call post_init
      puts "control_protocol initialize" if $debug or $verbose
      
      @cmd_prompt = "[cmds: h,?,k,d,q,x] ? "
      
    end  ## end of def initialize


    #############
    def post_init

      puts "control_protocol post_init" if $debug or $verbose
      
    end  ## end of def post_init


    ########################
    def connection_completed
      puts "control_protocol connection_completed" if $debug or $verbose
    end


    #####################
    def receive_data data

      send_data "Command Received: [#{data}] #{data.length} bytes\n"
      
      send_help if data[0,4] == 'help'
      send_help if data[0,3] == "h\r\n"
      send_help if data[0,3] == "?\r\n"

      EM.stop if data[0,4]  == 'kill'
      EM.stop if data[0,3]  == "k\r\n"

      close_connection if data[0,10]  == 'disconnect'
      close_connection if data[0,4]   == 'quit'
      close_connection if data[0,4]   == 'exit'
      close_connection if data[0,3]   == "d\r\n"
      close_connection if data[0,3]   == "q\r\n"
      close_connection if data[0,3]   == "x\r\n"
      
      
      send_data "peerrb control is active. Send 'help' (sans quotes) for menu.\n\n" if 2 == data.length
      send_data @cmd_prompt

    end  ## end of def receive_data data




    ###########################################################
    ## over-ride event_machine's send_data method to get
    ## some debuggin hooks in place
    
    def send_data data
    
      super
      
      puts "control_protocol  sent this: #{data}" if $debug_io || $debug
    
    end



    ################################################
    ## Send a help menu to client
    
    def send_help
      a_str  = "Commands for peerrb\n"
      a_str += "===================\n\n"
      a_str += "help ................ Prints this menu\n"
      a_str += "       (alias: h, ?)\n"
      a_str += "kill ................ Terminates this peerrb\n"
      a_str += "       (alias: k)\n"
      a_str += "disconnect .......... Disconnects this control session\n"
      a_str += "       (alias: quit, exit, d, q, x)\n\n"
      send_data a_str
    end



    #########################################################
    ## executed after the connection has already been dropped
    
    def unbind

      puts "control_protocol unbind" if $debug or $verbose
      EM.stop

    end  ## end of def unbind



  end ## end of class ControlProtocol


end ## end of module Peerrb


#########################################################






puts "Leaving: #{File.basename(__FILE__)}"  if $debug or $verbose

