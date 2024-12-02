class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.integer  "job_id",                              :null => false
      t.integer  "run_peer_id",         :default =>  0, :null => false ## Which model is the master of this Run
      t.integer  "user_id",                             :null => false
      t.integer  "notification_method",                 :null => false
      t.datetime "created_at",                          :null => false
      t.datetime "terminated_at"
      t.integer  "status",                              :null => false
      t.string   "debug_flags",         :limit =>   64, :null => false, :default => ""
      t.string   "guid",                :limit =>   36, :null => false
      t.string   "input_dir",           :limit => 2048, :null => false
      t.string   "output_dir",          :limit => 2048, :null => false

      t.timestamps
    end
  
    add_index :runs, :guid, :unique => true
    add_index :runs, :job_id
    add_index :runs, :user_id

  end
end
