class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :created_by_user_id,                 :null => false
      t.integer :updated_by_user_id
      t.string  :name
      t.string  :description
      t.string  :default_input_dir
      t.string  :default_output_dir
      t.string  :router
      
      t.timestamps
    end
    
    add_index :jobs, :name, :unique => true
    
  end
end
