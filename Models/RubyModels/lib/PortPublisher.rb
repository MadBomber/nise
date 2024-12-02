################################################################
###
##  File: PortPublisher.rb
##  Desc: Send a byte stream to a specific IP / PORT
#

require 'socket'
require 'string_mods'

class PortPublisher

  attr_reader :tcp_ip
  attr_reader :tcp_port
  attr_reader :connection

  def initialize(tcp_ip='138.209.52.147', tcp_port=50002)
  
    @tcp_ip     = tcp_ip
    @tcp_port   = 'String' == tcp_port.class.to_s ? tcp_port.to_i : tcp_port
    @connection = nil
    
    begin
      @connection = TCPSocket::new( @tcp_ip, @tcp_port )
      
      ISE::Log.info "#{self.class} established TCP connection with #{@tcp_ip}:#{@tcp_port}" #if $debug
      
    rescue Exception => e
      puts "ERROR: PortPublisher unable to open TCPSocket"
      puts "TCP Socket Error: #{e}"
      puts "       tcp_ip:    #{@tcp_ip}"
      puts "       tcp_port:  #{@tcp_port}"
      ISE::Log.error "#{self.class} cannot make TCP connection with #{@tcp_ip}:#{@tcp_port} because: #{e}"
    end
    
  end ## end of def initialize(tcp_ip, tcp_port)


  #################################
  # SMELL: Assumes data is a string
  def send_data(data)
  
    
    if @connection.nil? or data.nil? or data.empty?
      ISE::Log.error "Unable to send_data because either there is no connection or no data."
      return nil
    end
    
    begin
      @connection.send(data, 0)
      ISE::Log.debug "#{self.class} send to #{@tcp_ip}:#{@tcp_port} this: #{data.to_hex}" # if $debug
    rescue Exception => e
      ISE::Log.error "Got an Exception: #{e}"
      @connection = nil
      return nil
    end
  
  end ## end of def send_data(data)

end ## end of class PortPublisher
