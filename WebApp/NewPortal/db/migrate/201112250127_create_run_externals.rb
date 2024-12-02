# The run_externals table is being created to provide a place to associated
# non IseModels with an IseRun.  It is expected that the entries in this table
# will be managed by an IseModel.
class CreateRunExternals < ActiveRecord::Migration
  def change
  
    create_table "run_externals", :force => true do |t|
      t.integer  "run_id",                 :null => false, :default => 0
      t.integer  "node_id",                :null => false, :default => 0
      t.integer  "pid",                    :null => false, :default => 0
      t.integer  "status",                 :null => false, :default => 0
      t.timestamps
      t.text     "path",                   :null => false, :default => ""
    end

    add_index :run_externals, :run_id
    add_index :run_externals, :node_id

  end
end
