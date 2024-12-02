
# The control port for interactive commands
# TODO: define a different control port for each peer on the node

$dispatcher_control_port = 8010    ## SMELL: hardcoded port number; odd to be here and not IseDispatcher.rb


################################################################
## RunPeers is the ActiveRecord ORM class to the "run_peers" table in the
## Delilah database.  A "Peer" is an executing entity on the
## IseCluster.

class RunPeer < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to  :node
  has_one     :run
  has_many    :run_subscribers
  has_many    :run_models
  has_many    :dispatcher_stats

  #######################################################
  ## sends a command to an ISE peer returns
  ## the response received.

  def command(the_cmd)

    if the_cmd.class.to_s == "String" and the_cmd.length > 0

      the_response = "okay"
      
      begin
        puts "... sending via TCP the '#{the_cmd}' command to #{self.node.fqdn}" if $verbose
        control_socket = TCPSocket::new( self.node.fqdn, $dispatcher_control_port )
        control_socket.send( "#{the_cmd}\n\rd\n\r", 0 )    ## the ',d' is for disconnect
        the_response = control_socket.recv( 10000 )     ## SMELL: hardcoded number....this the number of characters to read
        puts "... received via TCP: #{the_response}" if $debug
		#puts "#{$the_response}\n"
        control_socket.close
      rescue Exception => e
        ERROR(["TCP Socket Error: #{e}",
          "Command was:  #{the_cmd}",
          "       host:  #{@host}",
          "  ctrl_port:  #{$dispatcher_control_port}"])
        the_response = nil
      end
    
    else
    
      the_response = nil
    
    end
    
    return the_response

  end ## end of def command(the_cmd)



  #######################################################
  ## sends a RESTful command to the IseDispatcher returns
  ## the response received.

  def restful_command(the_cmd)

    the_response = "okay"

    begin
    
      puts "... sending via HTTP the '#{the_cmd}' command to #{self.node.fqdn}" if $verbose

      the_response = Net::HTTP.start(self.node.ip_address, $dispatcher_control_port) do |http|
        http.get("/#{the_cmd}")
      end

      puts "... received via HTTP: #{the_response.inspect}" if $debug

    rescue Exception => e
      ERROR(["HTTP Socket Error: #{e}",
        "Command was:  #{the_cmd}",
        "       host:  #{self.node.fqdn}",
        " ip_address:  #{self.node.ip_address}",
        "  ctrl_port:  #{$dispatcher_control_port}"])
      the_response = nil
    end

    return the_response

  end ## end of def restful_command(the_cmd)

end ## end of class RunPeer < DelilahDatabase

__END__
Last Update: Tue Aug 10 14:06:48 -0500 2010

  create_table "run_peers", :force => true do |t|
    t.integer "node_id",                    :default => 0
    t.integer "pid",                        :default => 0,  :null => false
    t.integer "control_port",               :default => 0,  :null => false
    t.integer "status",                     :default => 0,  :null => false
    t.string  "peer_key",     :limit => 32, :default => "", :null => false
  end

  add_index "run_peers", ["node_id"], :name => "index_run_peers_on_node_id"
  add_index "run_peers", ["peer_key"], :name => "index_run_peers_on_peer_key"

