class CreateAppMessages < ActiveRecord::Migration
  def change
    create_table :app_messages do |t|
      t.string :app_message_key
      t.text :description

      t.timestamps
    end
    
    add_index :app_messages, :app_message_key, :unique => true

  end
end
