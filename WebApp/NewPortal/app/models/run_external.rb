################################################################
## RunExternal is the ActiveRecord ORM class to the "run_externals" table in the
## Delilah database.
##
## A RunExternal entry represents a program that is not an IseModel, that is being
## run as a component of an IseJob.  The run_externals table is managed by a simulation
## specific IseModel which is responsible for launching and killing external processes.

class RunExternal < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG

  belongs_to  :run
  belongs_to  :node
  
  # delete a specific run_externals entry
  def delete
    # TODO: ensure that the process is killed before deleting the record
    super
  end
  
end ## end of class RunExternal < ActiveRecord::Base


__END__
Last Update: Tue Aug 10 14:06:45 -0500 2010

  create_table "run_externals", :force => true do |t|
    t.integer  "run_id",     :default => 0, :null => false
    t.integer  "node_id",    :default => 0, :null => false
    t.integer  "pid",        :default => 0, :null => false
    t.integer  "status",     :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "path",                      :null => false
  end

  add_index "run_externals", ["node_id"], :name => "index_run_externals_on_node_id"
  add_index "run_externals", ["run_id"], :name => "index_run_externals_on_run_id"

