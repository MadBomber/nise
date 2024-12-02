#!/usr/bin/env ruby
#########################################################################
###
##  File: register_node.rb
##  Desc: Regrister an IseDrone into the IseDatabase Nodes table
##        The setup_symbols script must be run before this script will work.
##
##

require 'IseDatabase'   ## Classes and support methods
#require 'resolv'        ## stdlib: domain name service resolver
require 'rbconfig'      ## Ruby's configuration at build time
include RbConfig

#dns         = Resolv::DNS.new()
me          = ENV['HOSTNAME']     ## comes from setup_symbols
my_ip       = ENV['IPADDRESS']    ## dns.getaddress(me).to_s; comes from setup_symbols


my_dns_name = me

#begin
#    my_dns_name = dns.getname(my_ip) if me.nil?
#rescue
#    puts "WARNING: DNS not available"
#    puts "         my_ip: #{my_ip}    my_dns_name: #{my_dns_name}"
#end

my_platform = RUBY_PLATFORM       ## was CONFIG['host']

a_platform = Platform.find_by_name(my_platform)

if a_platform.nil?

  a_platform                = Platform.new
  a_platform.name           = my_platform
  a_platform.description    = "New platform; data record needs manual editing."
  a_platform.lib_path_name  = ""      ## Unknown
  a_platform.lib_path_sep   = ""      ## Unknown
  a_platform.lib_prefix     = "unk"   ## Unknown
  a_platform.lib_suffix     = "iml"   ## Unknown

  a_platform.save

  #puts "Added #{my_platform} as a new platform to ISE."
  #puts "Please edit the IseDatabase Platform table to ensure correct library prefix and suffix."

end

#puts "Found platform: #{my_platform}"
#puts "Looking for me: #{me}"

xxx = me.index('.') # look for a period; returns nil if not found
my_fullname = me
  
if xxx.nil?
  a_node = Node.find_by_name(me)
else
  me = me[0,xxx]  # extract the host name
  a_node = Node.find_by_fqdn(my_fullname)
end

if a_node.nil?

  a_node             = Node.new
  a_node.name        = me
  a_node.fqdn        = my_fullname
  a_node.description = 'A new IseDrone'
  a_node.ip_address  = my_ip
  a_node.status      = 0
  a_node.platform_id = a_platform.id

  a_node.save

  #puts "#{me} is now defined in the IseDatabase as node_id #{a_node.id}"

else

  #puts "#{me} is already defined as node_id #{a_node.id}"
  unless a_node.ip_address == ENV['IPADDRESS']
    #puts "The IP address has changed.  Was: #{a_node.ip_address} now: #{ENV['IPADDRESS']}"

    a_node.delete

    a_node             = Node.new
    a_node.id          = my_ip.split('.').last
    a_node.name        = me
    a_node.fqdn        = my_fullname
    a_node.description = 'A new IseDrone'
    a_node.ip_address  = my_ip
    a_node.status      = 0
    a_node.platform_id = a_platform.id

    a_node.save

  end ## end of unless a_node.ip_address == ENV['IPADDRESS']

end ## end of if a_node.nil?

