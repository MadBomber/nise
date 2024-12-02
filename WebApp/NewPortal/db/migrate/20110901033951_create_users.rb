class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.boolean :admin
      t.string :login
      t.string :name
      t.string :email
      t.string :phone_number

      t.timestamps
    end
  end
end
