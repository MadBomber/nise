class CreateDispatcherStats < ActiveRecord::Migration
  def change
    create_table :dispatcher_stats do |t|
      t.integer  "run_peer_id",              :null => false, :default => 0
      t.integer  "n_bytes",                  :null => false, :default => 0
      t.integer  "n_msgs",                   :null => false, :default => 0
      t.float    "mean_alive",               :null => false, :default => 0.0
      t.float    "stddev_alive",             :null => false, :default => 0.0
      t.float    "min_time_alive",           :null => false, :default => 0.0
      t.float    "max_time_alive",           :null => false, :default => 0.0
      t.string   "direction",  :limit =>  1, :null => false, :defailt => ""

      t.timestamps
    end
  
    add_index :dispatcher_stats, :run_peer_id
    add_index :dispatcher_stats, [ :run_peer_id, :direction ], :unique => true, :name => 'compound_index'

  end
end
