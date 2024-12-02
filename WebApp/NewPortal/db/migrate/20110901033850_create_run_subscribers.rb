class CreateRunSubscribers < ActiveRecord::Migration
  def change
    create_table :run_subscribers do |t|
      t.integer  "run_message_id",  :null => false, :default => 0
      t.integer  "instance",        :null => false, :default => 0
      t.integer  "run_peer_id",     :null => false, :default => 0

      t.timestamps
    end
  
    add_index :run_subscribers, :run_message_id
    add_index :run_subscribers, :run_peer_id

  end
end
