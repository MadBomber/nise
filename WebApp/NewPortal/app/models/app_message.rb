################################################################
## AppMessage is the ActiveRecord ORM class to the "app_messages" table in the
## Delilah database.
##

class AppMessage < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  
  has_many   :run_messages
  has_many   :run_subscribers, :through => :run_message

end ## end of class AppMessage < DelilahDatabase

__END__
Last Update: Tue Aug 10 14:06:50 -0500 2010

  create_table "app_messages", :force => true do |t|
    t.string "app_message_key", :limit => 32, :default => "", :null => false
    t.text   "description",                                   :null => false
  end

  add_index "app_messages", ["app_message_key"], :name => "index_app_messages_on_app_message_key", :unique => true

