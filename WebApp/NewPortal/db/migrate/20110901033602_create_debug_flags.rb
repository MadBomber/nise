class CreateDebugFlags < ActiveRecord::Migration
  def change
    create_table :debug_flags do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
