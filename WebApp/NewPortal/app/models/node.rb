################################################################
## Node is the ActiveRecord ORM class to the "nodes" table in the
## Delilah database.

class Node < ActiveRecord::Base
  # self.establish_connection $DELILAH_CONFIG

  # TODO: A Node can have many platforms just like platforms can have
  #       many nodes.  Need a has_many :through relationship
  # has_many :platforms,    :through => :node_platforms
  belongs_to :platform
  has_many   :job_configs
  has_many   :jobs,         :through => :job_config
  has_many   :models,       :through => :job_config
  has_many   :run_peers
  has_many   :run_externals


  
  def self.create (platform_id, name, desc, ip_address, status, fqdn)
  
    a_rec = self.new
    a_rec.platform_id = platform_id
    a_rec.name        = name
    a_rec.description = desc
    a_rec.ip_address  = ip_address
    a_rec.status      = status
    a_rec.fqdn        = fqdn

    a_rec.save
    
  end


  ##############################################################
  ## Return a node table entry by using a host name, IP or FQDN.

  def self.get_by_host(my_host)
    
    a_node = nil
    
    if my_host.class.to_s == "String"
      
      an_array = my_host.split('.')
      
      if an_array.length == 1                     ## Is it a simple name?
        a_node    = Node.find_by_name(my_host)
      elsif an_array.length == 4                  ## Is it an IP Address
        a_ip_i = an_array[0].to_i
        if an_array[0] == a_ip_i.to_s
          a_node    = Node.find_by_ip_address(my_host)
        else                                      ## assume its a a fully qualified domain name (FQDN)
          a_node    = Node.find_by_fqdn(my_host)
        end
      else                                        ## assume its an FQDN
        a_node    = Node.find_by_fqdn(my_host)
      end
    end
    
    return a_node
      
  end ## end of def get_by_host(my_host)

end   ## end of class Node < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:49 -0500 2010

  create_table "nodes", :force => true do |t|
    t.integer "platform_id",                                            :null => false
    t.integer "status",                                                 :null => false
    t.string  "name",        :limit => 64,                              :null => false
    t.string  "desc",        :limit => 1024,                            :null => false
    t.string  "ip_address",  :limit => 32,   :default => "192.168.0.0", :null => false
    t.string  "fqdn",        :limit => 128,                             :null => false
  end

  add_index "nodes", ["name"], :name => "index_nodes_on_name", :unique => true

