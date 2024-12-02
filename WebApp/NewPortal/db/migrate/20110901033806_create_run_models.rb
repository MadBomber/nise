class CreateRunModels < ActiveRecord::Migration
  def change
    create_table :run_models do |t|

      t.integer  "run_id",                 :null => false, :default => 0
      t.integer  "run_peer_id",            :null => false, :default => 0
      t.string   "dll",   :limit => 80,    :null => false, :default => 0
      t.integer  "instance",               :null => false, :default => 0
      t.integer  "dispnodeid",             :null => false, :default => 0
      t.float    "rate",                   :null => false, :default => 0
      t.boolean  "model_ready",            :null => false, :default => false
      t.boolean  "dispatcher_ready",       :null => false, :default => false
      t.integer  "status",                 :null => false, :default => 0
      t.float    "execute_time",           :null => false, :default => 0.0
      t.text     "extended_status",        :null => false, :default => ""

    end
  
    add_index :run_models, :run_id
    add_index :run_models, :run_peer_id
    add_index :run_models, :dll
  
  end
end
