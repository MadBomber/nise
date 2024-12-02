class CreateRunMessages < ActiveRecord::Migration
  def change
    create_table :run_messages do |t|

      t.integer  "run_id",              :null => false, :default => 0
      t.integer  "app_message_id",      :null => false, :default => 0
      t.integer  "ref_count",           :null => false, :default => 0

    end
  
    add_index :run_messages, :app_message_id
    add_index :run_messages, :run_id    
    add_index :run_messages, [:run_id, :app_message_id], :unique => true, :name => 'compound_index'
  
  end
end
