class CreateModels < ActiveRecord::Migration
  def change
    create_table :models do |t|
      t.integer :node_id
      t.integer :platform_id
      t.integer :created_by_user_id,                 :null => false
      t.integer :updated_by_user_id
      t.string  :name
      t.string  :description
      t.string  :location
      t.string  :dll
      t.string  :router

      t.timestamps
    end
  end
end
