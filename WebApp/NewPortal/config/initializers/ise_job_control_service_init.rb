######################################################################
###
##  File: ise_job_control_service_init.rb
##  Desc: Initialize Connection to the IseJobControl services
#

require 'drb'

service_class = 'IseJobControl'
service_ip    = '127.0.0.1'
service_port  = 9000
service_uri   = "druby://#{service_ip}:#{service_port}"

# SMELL: This will produce an exception in irb when the
#        service is not available; BUT, outside of irb
#        it does not produce an exception.

$ise_job_control_service = DRbObject.new_with_uri(service_uri)

# So, we add our own alive? method to the service to force the exception

def ise_job_control_service_is_alive?
  begin
    answer = $ise_job_control_service.alive?
  rescue DRb::DRbConnError
    ISE::Log.warn "#{$ise_job_control_service.__drburi} service is down."
    answer = false
  end
  return answer
end

