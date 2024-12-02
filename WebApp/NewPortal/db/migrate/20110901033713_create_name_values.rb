class CreateNameValues < ActiveRecord::Migration
  def change
    create_table :name_values do |t|
      t.string :name
      t.text :value

      t.timestamps
    end
  end
end
