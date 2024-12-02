class CreateRunModelOverrides < ActiveRecord::Migration
  def change
    create_table :run_model_overrides do |t|
      t.integer :run_id
      t.integer :user_id
      t.integer :model_id
      t.integer :instance
      t.string :cmd_line_param
      t.string :debug_flags

      t.timestamps
    end
  end
end
