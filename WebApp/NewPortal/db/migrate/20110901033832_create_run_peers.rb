class CreateRunPeers < ActiveRecord::Migration
  def change
    create_table :run_peers do |t|
      t.integer  "node_id",                                :default => 0
      t.integer  "pid",                    :null => false, :default => 0
      t.integer  "control_port",           :null => false, :default => 0
      t.integer  "status",                 :null => false, :default => 0
      t.string   "peer_key", :limit => 32, :null => false, :default => ""
      t.timestamps
    end
    
    add_index :run_peers, :node_id
    add_index :run_peers, :peer_key
    
  end
end
