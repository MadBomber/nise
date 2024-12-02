################################################################
## KeyValue is the ActiveRecord ORM class to the "key_values" table in the
## Delilah database.
##

class NameValue < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  def self.create (name, value)
  
    a_rec = self.new
    a_rec.name  = name
    a_rec.value = value
    a_rec.save
    
  end


end ## end of class NameValue < DelilahDatabase

__END__
Last Update: Tue Aug 10 14:06:46 -0500 2010

  create_table "name_values", :force => true do |t|
    t.string "name",  :limit => 32, :default => "", :null => false
    t.text   "value",                               :null => false
  end

  add_index "name_values", ["name"], :name => "index_name_values_on_name", :unique => true

