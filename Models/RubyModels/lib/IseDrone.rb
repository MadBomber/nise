=begin
  File: IseDrone.rb
  Desc: Methods that support regristering an IseDrone into the IseDatabase

  SMELL: You could argue that these methods should really be in the nodes model
=end

require 'IseDatabase'               ## all the database classes and utility methods

class IseDrone

  @@ise_drone = nil

  def self.exist?(a_name=nil)

    @@ise_drone = get_me if a_name.nil?

    return @@ise_drone
  end

  def self.register
    return @@ise_drone
  end

  private
  def self.get_me
    #require 'resolv'        ## stdlib: domain name service resolver
    require 'rbconfig'      ## Ruby's configuration at build time
    include RbConfig

   # dns         = Resolv::DNS.new()
    me          = ENV['HOSTNAME']     ## comes from setup_symbols
    my_ip       = ENV['IPADDRESS']    ## dns.getaddress(me).to_s; comes from setup_symbols

    my_dns_name = me
    #begin
    #  my_dns_name = dns.getname(my_ip)
    #rescue
    #  # my_dns_name should still be me
    #end

    xxx = me.index('.') # look for a period; returns nil if not found
    my_fullname = me

    if xxx.nil?
      a_node = Node.find_by_name(me)
    else
      me = me[0,xxx]  # extract the host name
      a_node = Node.find_by_fqdn(my_fullname)
    end


  end

end ## end of class IseDrone
