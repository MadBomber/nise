class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.integer :platform_id
      t.integer :status
      t.string :name
      t.string :description
      t.string :ip_address
      t.string :fqdn

      t.timestamps
    end
  end
end
