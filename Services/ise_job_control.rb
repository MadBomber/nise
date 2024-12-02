#!/usr/bin/env ruby
######################################################################
###
##  File: ise_job_control.rb
##  Desc: Provides IseJob control services
##        Makes use of an Access Control List.  The ACL only allows access
##        from a specific set of IP addresses and computer hostnames.
##
##  Command Line Usage:
##
##    ise_job_control.rb [port]
##
##      port (optional)   The port on which to wait for service requests.
##                        Default: 9000
##
##
##  Example Client Usage:
##
##    require 'drb'
##    ijc = DRbObject.new_with_uri "druby://127.0.0.1:9000" # Use the IP/Port of the service if not localhost
##    ijc.services  # gets Hash of services
##    ijc.alive?    # returns true or an exception
##
##    if the client's IP address is not explicitly allowed any method
##    sent to the remote service will generate an exception.
##
## TODO: register service with central IseServiceRegristery
#

require 'ise_logger'
ISE::Log.new

require 'IseDatabase'
require 'IseDispatcher'
require 'debug_me'

require 'drb/drb'
require 'drb/acl'
require 'pathname'
require 'notify'
require 'systemu'
require 'dnssd'

#$SAFE = 1  # disable eval, system and friends

# NOTE: DRb author recommends use of firewall for increased security
acl = ACL.new(  %w{ allow 138.209.69.248
                    allow 138.209.52.0/24
                    allow 127.0.0.1
                  },
                ACL::ALLOW_DENY
             )

DRb.install_acl(acl)



service_type  = '_druby._tcp'
service_class = 'IseJobControl'   # NOTE: Should match the class name

# SMELL: The avahi tools look like they require the service_name to be unique across computers
service_name = service_class+'_'+ENV['IPADDRESS']


##########################################################
## Exceptions

UnknownIseJob = 'UnknownIseJob'
InvalidRunId  = 'InvalidRunId'


##########################################################
## Process System Environment Variables

if ENV['ISE_ROOT'].nil? or ENV['ISE_QUEEN'].nil?
  $stderr.puts
  $stderr.puts "ERROR: Required environment variables are not defined."
  $stderr.puts
  $stderr.puts "       Seems like setup_symbols has not yet been run. "
  $stderr.puts
  exit(1)
end

$ISE_ROOT   = Pathname.new(ENV['ISE_ROOT'])
$ISE_QUEEN  = Pathname.new(ENV['ISE_QUEEN'])


##########################################################
# Default Command Line Parameters

port = 9000


##########################################################
## Process Command Line Parameters

unless ARGV.empty?
  port = ARGV[0].to_i
end




##########################################################
## BlankSlate class provides only this methods that are considered safe

class BlankSlate
  safe_methods = %w{__send__ __id__ inspect respond_to? to_s}
  (instance_methods - safe_methods).each do |method|
    undef_method method
  end
end



##########################################################
## IseJobControl class encapsulates the Drb services provided by
## this file.

class IseJobControl # < BlankSlate

  # a hash that describes the services offered
  attr_reader :services

  def initialize(service_port)
    @debug_service  = false
    @services       = {
      :service_name       => "Returns the string: #{self.class}",
      :service_class      => "Same as :service_name",
      :alive?             => "Returns true; or you will get an exception",
      :terminate_service  => "Terminate the service",
      :services           => "Returns a hash of services available",
      :launch             => "Launch an IseJob; Params: job (id|name), debug_mode=false, grid_mode=false",
      :running?           => "Returns true|false; Params: run_id",
      :kill_run           => "Kill an existing IseRun; Params: run_id",
      :remote_system      => "Execute a bash shell command; Params: a_command",
      :remote_systemu     => "Execute a bash shell command returning process id, stdout, stderr in an array; Params: a_command",
      :debug_service      => "Returns true|false to indicate state of service debug flag",
      :debug_service=     => "Set service debug_state; Params: true|false",
      :env                => "Return value of environment variable; Params: variable_name",
      :env_all            => "Return Hash of all environment variables and their values",
      :set_env            => "Set the value of an Environmant Variable; Params: env_name, env_value",
      :get_env            => "Same as :env",
      :get_env_all        => "Same as :env_all",
      :start              => "Same as :launch",
      :status             => "Same as :running?",
      :stop               => "Same as :kill_run"
    }
  end


  #######################################################
  ## Return the class name as a string

  def service_name
    debug_me  if @debug_service
    self.class.to_s
  end

  alias :service_class :service_name


  #######################################################
  ## Tell client that server is alive

  def alive?
    debug_me  if @debug_service
    return true
  end


  ###########################################################
  ## Terminate the service

  def terminate_service
    debug_me  if @debug_service
    DRb.stop_service
    msg = "#{self.class} service is terminating ..."
    #puts msg
    ISE::Log.info msg
  end


  #######################################################
  ## Start a specific job configuration
  def launch(job, debug_mode=false, grid_mode=false)

    debug_me  if @debug_service

    case job.class.to_s
      when 'Fixnum' then
        begin
          ise_job = Job.find(job)
        rescue
          ise_job = nil
        end
      when 'String' then
        begin
          ise_job = Job.find_by_name(job)
        rescue
          ise_job = nil
        end
      when 'Job' then
        ise_job = job
      else
        raise UnknownIseJob
    end

    raise UnknownIseJob if ise_job.nil?

    return ise_job.launch     # TODO: forward debug and grid parameters to Job#launch

  end

  alias :start :launch


  #######################################################
  ## Status a specific run
  def running?(run_id=nil)

    debug_me  if @debug_service

    raise InvalidRunId unless 'Fixnum' == run_id.class.to_s

    begin
      r = Run.find(run_id)
    rescue
      raise InvalidRunId
    end

    return (r.status > 0)

  end

  alias :status :running?


  #######################################################
  ## Stop a specific run
  def kill_run(run_id=nil)

    debug_me  if @debug_service

    raise InvalidRunId unless 'Fixnum' == run_id.class.to_s

    IseDispatcher.new.kill_run(run_id)

  end

  alias :stop :kill_run


  ##########################################################
  ## Systen Commands

  def remote_system(a_command=nil)
    debug_me  if @debug_service

    system(a_command) unless a_command.nil?

  end


  def remote_systemu(a_command=nil)
    debug_me  if @debug_service

    if a_command.nil?
      answer = [nil, nil, nil]
    else
      a,b,c = systemu(a_command)
      answer = [a, b, c]
    end

    return answer

  end


  ##########################################################
  ## Debug Tools

  def debug_service
    debug_me  if @debug_service
    @debug_service
  end

  def debug_service=(debug_state)
    debug_me  if @debug_service
    @debug_service = debug_state
  end


  #######################################################
  ## Tell client the value of an environment variable

  def env(var='xyzzy')
    debug_me  if @debug_service
    return ENV[var]
  end
  
  alias :get_env :env

  def env_all
    debug_me  if @debug_service
    return(ENV.to_a)
  end
  
  alias :get_env_all :env_all
  
  def set_env(env_name=nil, env_value='nil')
    unless env_name.nil?
      ENV[env_name] = env_value
    end
  end

end ## end of class IseJobControl


ISE_JOB_CONTROL = IseJobControl.new(port)

my_uri = "druby://0.0.0.0:#{port}"   # Use all valid IP addresses for this box.

begin
  DRb.start_service my_uri, ISE_JOB_CONTROL
rescue
  service = DRbObject.new_with_uri(my_uri)
  the_other_service_class = service.service_class
  if service_class == the_other_service_class
    service.terminate_service
    sleep(0.5) # allow old process some time to die gracefully
    retry
  else
    msg = "#{service_class} unable to start on #{port} because it is currently in use by #{the_other_service_class}."
    STDERR.puts "ERROR: #{msg}"
    ISE::Log.error msg
    Notify.notify(service_class, msg)
    exit(99)
  end
end

msg = "#{ENV['USER']} started #{service_class} service running at #{DRb.uri}"

ISE::Log.info msg
Notify.notify(service_class,"Service started on port #{port}.")



# SMELL: Control-C does not stop the Drb server on Ruby version 1.9.2
trap("INT") do
  DRb.stop_service
  msg = "User requested termination of #{service_class}."
  STDERR.puts msg
  ISE::Log.info msg
  Notify.notify(service_class, msg)
  exit(1)
end

DNSSD.register(service_name, service_type, 'local', port)

DRb.thread.join

msg = "Service has terminated normally."

Notify.notify(service_name, msg)
ISE::Log.info("#{service_class}: #{msg}")

