##############################################################
###
##  File: IseDispatcher.rb
##  Desc: The control class of the ISE dispatchers
#

require 'rubygems'
require 'socket'
require 'net/http'
require 'net/ssh'
require 'snmp'
#include SNMP

require 'rubygems'
require 'RedCloth'    ## GEM: provides Textile markup for generating HTML

require 'debug_me'


###################################################################
## IseDispatcher is a subset of the run_peers table.  The
## class contains all stuff associated with the ISE dispatchers.

class IseDispatcher

  # The record in the nodes table associated with "my_host".
  attr_accessor :node

  # The record in the run_peers table associated with this dispatcher
  attr_accessor :run_peer


  ####################################################
  ## create a new instance of the IseDispatcher class
  ## the default is for the current host on which
  ## the script is running; but, could be for any host

  def initialize( my_host = $HOSTNAME )
    @conf_file = "dispatcherd.conf"
    @node     = Node.get_by_host(my_host)
    @run_peer = nil
    unless @node.nil?
      get_me
    end
	
    puts "Dispatcher Object initialization complete on #{@node.name}" if $verbose
  end ## end of def initialize

  ####################################################
  ##

  def conf( my_conf_file = "")
	@conf_file = my_conf_file unless my_conf_file.empty?
	puts "Initialization file: (#{@conf_file})" if $verbose
  end


  ##################################################################
  ## Get the run_peer record associated with this host.  There
  ## should be only 1 record (dispatcher) per host.

  def get_me

    a_run_peer = RunPeer.find( :all,
    :conditions => "peer_key = 'dispatcher' and node_id = '#{@node.id}'")

    if a_run_peer.empty?          ## not enought
      @run_peer = nil
    elsif a_run_peer.length == 1  ## perfect number, just what was expected
      @run_peer = a_run_peer[0]
    elsif a_run_peer.length > 1   ## too many
      ERROR([ "Too many dispatchers on a single node.",
        "Node:  #{@node.fqdn}",
        "Count: #{a_run_peer.length}"])
      @run_peer = nil
    else                          ## should never catch the condition
      @run_peer = nil
      ERROR(["Internal system error."])
    end

  end ## end of def get_me

  ################################################################
  ## running? returns boolean based upon whether dispatcher record
  ## is in running_peers table.

  def record_exists?

    return (not @run_peer.nil?)

  end
  
  
  #####################################
  ## Used by the kill_run method
  ## Checks the status of a Run record
  
  def run_complete? (run_id)
  
    return  0 == Run.find(run_id).status

  end
  
  #####################################
  ## Used by the kill_run method
  ## Checks the status of a RunPeer record
  
  def run_peer_complete? (run_peer_id)
  
    return  0 == RunPeer.find(run_peer_id).status

  end

  ################################################################
  ## running? returns boolean based upon whether dispatcher record
  ## is in running_peers table.

  def running?

    #puts "Running test on #{@node.name}"
    #caller.each {|c| puts c}
    #return (not @run_peer.nil?)

    if record_exists?

      snmp = SNMP::Manager.new(:Host => @node.ip_address,:Community => 'ise')
      puts "SNMP Query for MIB=1.3.6.1.2.1.25.4.2.1.1.#{@run_peer.pid}  NODE: #{@node.name}" if $verbose
      begin
        response = snmp.get(["1.3.6.1.2.1.25.4.2.1.1.#{@run_peer.pid}"])
        response.each_varbind do |vb|
          puts vb.inspect if $verbose
          return vb.value.to_s != "noSuchInstance"
        end
      rescue SNMP::RequestTimeout
        puts "No SNMP response from node #{@node.name}"
        return true  # give the benefit of the doubt!
      end
    else
      return false
    end

  end

  ################################################################
  ## JKL: verify up and running

  def running_really?
    return running? ? @run_peer.restful_command("alive") : nil
  end


  ################################################################
  ## kill the dispatcher currently executing on the this host

  def kill

    if not record_exists?
      ERROR([ "There is no record of an IseDispatcher running on #{@node.name}."])
      puts self.inspect
      return nil
    elsif not running?
      ERROR([ "IseDispatcher process not on #{@node.name}."])
      RunPeer.delete(@id)
    end

    puts "Stop (aka kill, quit) the dispatcher on node: #{@node.name} #{@node.ip_address}" if $verbose

    @run_peer.restful_command("quit")

    puts "Waiting for confirmation of successful kill ..." if $verbose

    5.times do |a_step| ## SMELL: hardcoded time-outs
      sleep 2           ## give the program some time to get killed
      get_me
      if record_exists?
        puts "... still waiting" if $verbose
      else
        puts "... dispatcher on #{@node.name} killed at #{Time.now}" if $verbose
      end
      break unless record_exists?
    end
  
    ERROR([ "Unable to kill the IseDispatcher on #{@node.fqdn}"]) if record_exists?

  end ## end of def kill



  #####################################################
  ## Tell the IseDispatcher to kill a specific IseModel
  def kill_model (run_peer_id)
  
    if not record_exists?
      ERROR([ "There is no record of an IseDispatcher running on #{@node.name}."])
      puts self.inspect
      return nil
    elsif not running?
      ERROR([ "IseDispatcher process not on #{@node.name}."])
      RunPeer.delete(@id)
    end

    puts "Stop (aka kill, quit) run_peer_id #{run_peer_id}" if $verbose

    @run_peer.restful_command("kill.xml?model=#{run_peer_id}")

    puts "Waiting for confirmation of successful kill ..." if $verbose

    3.times do |a_step| ## SMELL: hardcoded time-outs
      sleep 2           ## give the program some time to get killed
      get_me
      unless run_peer_complete? run_peer_id
        puts "... still waiting" if $verbose
      else
        puts "... RunPeerID #{run_peer_id} killed at #{Time.now}" if $verbose
      end
      break if run_peer_complete? run_peer_id
    end
  
    ERROR([ "Unable to kill the RunPeerID #{run_peer_id}"]) unless run_peer_completed? run_peer_id

  end
  
  ###################################################
  ## Tell the IseDispatcher to kill a specific IseRun
  def kill_run (run_id)
  
    if not record_exists?
      ERROR([ "There is no record of an IseDispatcher running on #{@node.name}."])
      puts self.inspect
      return nil
    elsif not running?
      ERROR([ "IseDispatcher process not on #{@node.name}."])
      RunPeer.delete(@id)
    end

    puts "Stop (aka kill, quit) run_id #{run_id}" if $verbose

    @run_peer.restful_command("kill.xml?job=#{run_id}")

    puts "Waiting for confirmation of successful kill ..." if $verbose

    3.times do |a_step| ## SMELL: hardcoded time-outs
      sleep 2           ## give the program some time to get killed
      get_me
      unless run_complete? run_id
        puts "... still waiting" if $verbose
      else
        puts "... RunID #{run_id} killed at #{Time.now}" if $verbose
      end
      break if run_complete? run_id
    end

    ERROR([ "Unable to kill the RunID #{run_id}"]) unless run_complete? run_id

  end





  #########################################################
  ## stats asks the local dispatcher for its statistics
  ## report and prints the report to the screen

  def stats

    # FIXME: error in the parser, need xml for now - 11/1/2008
    return running? ? (puts @run_peer.restful_command("stats.xml") unless nil ) : nil

  end ## end of def stats


  #########################################################
  ## models asks the local dispatcher for its list of
  ## attached models and prints the report to the screen

  def models

    return running? ? @run_peer.restful_command("models") : nil

  end ## end of def models

  #########################################################
  ## ident asks the local dispatcher to identify itself
  ## and prints the report to the screen

  def ident

    return running? ? @run_peer.restful_command("identity") : nil

  end ## end of def ident


  #############################################################
  ## Start a dispatcher on the @host

  def start

    if running_really?
      #ERROR([ "IseDispatcher process currently on #{@node.name}."])
      puts "IseDispatcher process currently on #{@node.name}."
      return nil
    end

    puts "Starting an IseDispatcher on #{@node.name} ..." if $verbose
    puts "... attached to the RDBMS at #{ENV['ISE_QUEEN']}" if $verbose

    the_dispatcher  = $ISE_ROOT + "bin" + "ise_main"
    the_config_file = $ISE_ROOT + "etc" + "ISE" + @conf_file
	the_params      = " -b -f " + the_config_file.to_s



    if @node.ip_address == Node.get_by_host($HOSTNAME).ip_address
      the_cmd = the_dispatcher.to_s + the_params  ## for local computer
      puts "Execute: #{the_cmd}" if $verbose
      system the_cmd                              ## FIXME: Not cross-platform
    else                                          ## for remote computer
      #the_cmd = "ssh #{@node.fqdn} -x 'cd #{$ISE_ROOT};. setup_symbols; " + the_dispatcher.to_s + the_params + "'" # SMELL: cross-platform ??
      Net::SSH.start(@node.fqdn,ENV['USER']) do |ssh|
        channel = ssh.open_channel do |ch|
          ## FIXME: Not cross-platform
          ch.exec("cd #{$ISE_ROOT}; . setup_symbols; " + the_dispatcher.to_s + the_params)

          # "on_data" is called when the process writes something to stdout
          ch.on_data { |c, data| $STDOUT.print data }

          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data { |c, type, data| $stderr.print data }

          ch.on_close { puts "start dispatcher command sent!" if $verbose }
        end
        channel.wait
      end

    end



    puts "Waiting for confirmation of successful start ..." if $verbose

    5.times do |a_step|
      sleep 2           ## give the program some time to get started
      get_me
      if record_exists? and @run_peer.status == 2
        puts "... started at #{Time.now}" if $verbose
      else
        puts "... still waiting" if $verbose
      end
      break if record_exists? and @run_peer.status == 2
    end

    ERROR([ "Unable to start the IseDispatcher."]) unless record_exists? and @run_peer.status == 2

  end ## end of def start





  ###################
  ## class methods ##
  ###################


  ######################################################
  ## The anneal command tells an IseDispatcher to update
  ## its routing tables with the IseDatabase.

  def self.anneal

    all_dispatchers = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher'")

    if all_dispatchers.empty?
      puts "IseDatabase reports that no IseDispatchers are currently running on the IseCluster."
      return nil
    end

    dispatcher_ghosts = false

    all_dispatchers.each do |dispatcher|

      the_response = dispatcher.restful_command("anneal")

      if the_response
        puts the_response.body if $verbose
      else
        dispatcher_ghosts = true
      end

    end

    if dispatcher_ghosts
      puts "Some IseDispatchers are not responding to an anneal request."
    end

  end ## end of def self.anneal


  ######################################################
  ## The anneal_crash method is identical to the anneal
  ## method except it does not use the RESTful command protocol.

  def self.anneal_crash

    all_dispatchers = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher'")

    if all_dispatchers.empty?
      puts "IseDatabase reports that no IseDispatchers are currently running on the IseCluster."
      return nil
    end

    dispatcher_ghosts = false

    all_dispatchers.each do |dispatcher|

      the_response = dispatcher.command("anneal")

      if the_response
        puts the_response
      else
        dispatcher_ghosts = true
      end

    end

    if dispatcher_ghosts
      puts "Some IseDispatchers are not responding to an anneal request."
      puts "You may need to do a 'clean' command."
    end

  end ## end of def Dispatcher.anneal_crash


  ######################################################
  ## what does this do?

  def self.list (output_format=:text)

    error_message = ""

=begin
    list_report_html_and_wiki  = "|_.Active?"     ## This is the RedCloth markup, conversion to the wiki markup
    list_report_html_and_wiki += "|_.PID"         ## just requires the removal of the "_." characters.
    list_report_html_and_wiki += "|_.RunPeer ID"
    list_report_html_and_wiki += "|_.Node ID"
    list_report_html_and_wiki += "|_.Node Name"
    list_report_html_and_wiki += "|_.Node Description"
    list_report_html_and_wiki += "|\n"
=end

    case output_format.to_s
    when "text" then
      list_report = "\n"
#    when "html" then                    ## This uses the RedCloth markup
#      list_report  = list_report_html_and_wiki
#    when "wiki" then                    ## Wiki markup consistent with TWiki and FOSWIKI
#      list_report  = list_report_html_and_wiki.gsub('_.', '')
    when "xml" then
      list_report = "<xml>\n"
    when "yaml" then
      list_report = ""
    when "json" then
      list_report = ""
    else
      list_report = ""
    end

    all_dispatchers = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher'")

    if all_dispatchers.empty?
      error_message += "IseDatabase reports that no IseDispatchers are currently running on the IseCluster.\n"
    else

      dispatcher_counter = 0

      all_dispatchers.each do |dispatcher|

        dispatcher_counter += 1

        the_response = dispatcher.restful_command("alive")

        if the_response
          responding = "   "
        else
          responding = "Not"
        end

        list_report_html_and_wiki  = "|#{responding} Responding"
        list_report_html_and_wiki += "|#{dispatcher.pid}"
        list_report_html_and_wiki += "|#{dispatcher.id}"
        list_report_html_and_wiki += "|#{dispatcher.node.id}"
        list_report_html_and_wiki += "|#{dispatcher.node.name}"
        list_report_html_and_wiki += "|#{dispatcher.node.description}"
        list_report_html_and_wiki += "|<a href='http://#{dispatcher.node.ip_address}:8010/'>Show</a>"
        list_report_html_and_wiki += "|\n"


        case output_format.to_s
        when "text" then
          list_report += "#{responding} Responding PID:#{dispatcher.pid} RunPeer:#{dispatcher.id} "
          list_report += "Node:#{dispatcher.node.id} #{dispatcher.node.ip_address} #{dispatcher.node.name} -- #{dispatcher.node.description}\n"
        when "html" then
          list_report += list_report_html_and_wiki
        when "wiki" then
          list_report += list_report_html_and_wiki
        when "xml" then
          list_report += dispatcher.to_xml(:skip_instruct => true,:include =>  [ :node ])
        when "yaml" then
          list_report += dispatcher.to_yaml
        when "json" then
          list_report += "," if dispatcher_counter > 1
          list_report += dispatcher.to_json(:include =>  [ :node ])
        else
          list_report += ""
        end ## end of case output_format.to_s

      end ## end of all_dispatchers.each do |dispatcher|

    end   ## end of if all_dispatchers.empty?

    case output_format.to_s
    when "text" then
      list_report += "\n"
      list_report += error_message if error_message.length > 0
    when "html" then
      list_report += "\n"
      list_report += "\n" + error_message if error_message.length > 0
      r = RedCloth.new list_report
      list_report = r.to_html
    when "wiki" then
      list_report += "\n"
      list_report += "\n" + error_message if error_message.length > 0
    when "xml" then
      list_report += "<error>" + error_message + "</error>" if error_message.length > 0
      list_report += "</xml>\n"
    when "yaml" then
      list_report += "\n" + error_message if error_message.length > 0
    when "json" then
      list_report = error_message.to_json if error_message.length > 0
      list_report = "[" + list_report + "]" if dispatcher_counter > 1
    else
      list_report += ""
    end ## end of case output_format.to_s

    return list_report

  end ## end of def self.list (clean=false)


  ###################################################################
  ## clean looks at all dispatchers maintained in the run_peers table
  ## if the dispatcher does not responde to a query, its record in
  ## run_peers is deleted

  def self.clean

    all_dispatchers = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher'")

    unless all_dispatchers.empty?

      all_dispatchers.each { |dispatcher| RunPeer.delete(dispatcher.id) unless dispatcher.restful_command("alive") }

    end

  end ## end of def self.clean


  ##########################################################
  ## Tell all ISE Dispatchers in the run_peers table to quit
  ## SMELL: danger, danger Will Robinson

  def self.killall

    puts "Killing all dispatchers on the world-wide ISE grid ..." if $verbose

    all_dispatchers = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher'")

    if all_dispatchers.empty?
      puts "The IseDatabase has no record of any running IseDispatchers."
    else
      all_dispatchers.each { |dispatcher| dispatcher.restful_command("quit") }
    end

  end     ## end of def self.killall


  #######################################################
  ## Tell all ISE Dispatchers in the $ISE_CLUSTER to quit


  def self.killcluster

    puts "Killing all dispatchers on the local ISE grid cluster ..." if $verbose

    $ISE_CLUSTER.each do |a_node|

      the_node      = Node.get_by_host(a_node)

      if the_node

        dispatcher = RunPeer.find(:all, :conditions => "peer_key = 'dispatcher' and node_id = #{the_node.id}")

        unless dispatcher[0].nil?
          dispatcher[0].restful_command("quit")
        end

      end ## end of if the_node.nil?
    end   ## end of the_cluster = $ISE_CLUSTER.split(' ')
  end     ## end of def self.killcluster
end       ## end of class IseDispatcher
