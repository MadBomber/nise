################################################################
## StatusCode is the ActiveRecord ORM class to the "status_codes" table in the
## Delilah database.
##

class StatusCode < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  def self.create (code, desc)
  
    a_rec             = self.new
    a_rec.code        = code
    a_rec.description = desc
    a_rec.save
    
  end
  
end ## end of class StatusCode < DelilahDatabase

__END__
Last Update: Tue Aug 10 14:06:47 -0500 2010

  create_table "status_codes", :force => true do |t|
    t.integer "code", :default => 0, :null => false
    t.text    "desc",                :null => false
  end

  add_index "status_codes", ["code"], :name => "index_status_codes_on_code", :unique => true

