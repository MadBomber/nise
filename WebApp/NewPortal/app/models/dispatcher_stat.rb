################################################################
## DebugFlag is the ActiveRecord ORM class to the "dispatcher_stats" table in the
## Delilah database.
##

class DispatcherStat < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to :run_peer
  
end ## end of class DispatcherStat < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:44 -0500 2010

  create_table "dispatcher_stats", :force => true do |t|
    t.integer "run_peer_id",                 :default => 0,   :null => false
    t.integer "n_bytes",                     :default => 0,   :null => false
    t.integer "n_msgs",                      :default => 0,   :null => false
    t.float   "mean_alive",                  :default => 0.0, :null => false
    t.float   "stddev_alive",                :default => 0.0, :null => false
    t.float   "min_time_alive",              :default => 0.0, :null => false
    t.float   "max_time_alive",              :default => 0.0, :null => false
    t.string  "direction",      :limit => 1,                  :null => false
  end

  add_index "dispatcher_stats", ["run_peer_id", "direction"], :name => "compound_index", :unique => true
  add_index "dispatcher_stats", ["run_peer_id"], :name => "index_dispatcher_stats_on_run_peer_id"

