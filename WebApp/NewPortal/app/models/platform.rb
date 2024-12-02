################################################################
## Platform is the ActiveRecord ORM class to the "platforms" table in the
## Delilah database.

class Platform < ActiveRecord::Base
  # self.establish_connection $DELILAH_CONFIG
  
  has_many   :nodes

#  has_many   :nodes,         :through => :models, :through => :job_configs

  def self.create (name, lib_prefix, lib_suffix, lib_path_name, lib_path_sep, desc)
  
    a_rec = self.new
    a_rec.name          = name
    a_rec.lib_prefix    = lib_prefix
    a_rec.lib_suffix    = lib_suffix
    a_rec.lib_path_name = lib_path_name
    a_rec.lib_path_sep  = lib_path_sep
    a_rec.description   = desc
    a_rec.save
    
  end

end ## end of class Platform < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:45 -0500 2010

  create_table "platforms", :force => true do |t|
    t.string "name",          :limit => 64,   :null => false
    t.string "lib_prefix",    :limit => 16,   :null => false
    t.string "lib_suffix",    :limit => 16,   :null => false
    t.string "lib_path_name", :limit => 32,   :null => false
    t.string "lib_path_sep",  :limit => 1,    :null => false
    t.string "desc",          :limit => 1024, :null => false
  end

  add_index "platforms", ["name"], :name => "index_platforms_on_name", :unique => true

