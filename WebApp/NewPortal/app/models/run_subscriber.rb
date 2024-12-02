=begin

Considering making this run_pubsub with the addtion of the following
columns:

  pub_sub :integer(4)    0 == sub;  1 == pub
  app_message_id     forn key to the app_message table
  
  removing the run_message_id
  
  changing "instance" to something more meaningful

=end


################################################################
## Subscriber is the ActiveRecord ORM class to the "run_subscribers" table in the
## Delilah database.
##

class RunSubscriber < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to  :run
  belongs_to  :run_model
  belongs_to  :run_message
  
end ## end of class RunSubscriber < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:47 -0500 2010

  create_table "run_subscribers", :force => true do |t|
    t.integer "run_message_id", :default => 0, :null => false
    t.integer "instance",       :default => 0, :null => false
    t.integer "run_peer_id",    :default => 0, :null => false
  end

  add_index "run_subscribers", ["run_message_id"], :name => "index_run_subscribers_on_run_message_id"
  add_index "run_subscribers", ["run_peer_id"], :name => "index_run_subscribers_on_run_peer_id"

