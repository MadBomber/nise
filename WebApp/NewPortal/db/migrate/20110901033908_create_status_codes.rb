class CreateStatusCodes < ActiveRecord::Migration
  def change
    create_table :status_codes do |t|
      t.integer :code
      t.text :description

      t.timestamps
    end
    add_index :status_codes, :code, :unique => true
  end
end
