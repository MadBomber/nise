class CreatePlatforms < ActiveRecord::Migration
  def change
    create_table :platforms do |t|
      t.string :name
      t.string :description
      t.string :lib_prefix
      t.string :lib_suffix
      t.string :lib_path_name
      t.string :lib_path_sep

      t.timestamps
    end
  end
end
