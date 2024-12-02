################################################################
## RunModel is the ActiveRecord ORM class to the "run_models" table in the
## Delilah database.
##
## A RunModel entry can be linked to a Model entry via RunModel.dll == Model.location ???

class RunModel < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to  :run
  belongs_to  :run_peer

end ## end of class RunModel < DelilahDatabase

# TODO: Consider making 'instance' more meaningful

__END__
Last Update: Tue Aug 10 14:06:48 -0500 2010

  create_table "run_models", :force => true do |t|
    t.integer "run_id",                         :default => 0,     :null => false
    t.integer "run_peer_id",                    :default => 0,     :null => false
    t.string  "dll",              :limit => 80, :default => "0",   :null => false
    t.integer "instance",                       :default => 0,     :null => false
    t.integer "dispnodeid",                     :default => 0,     :null => false
    t.float   "rate",                           :default => 0.0,   :null => false
    t.boolean "model_ready",                    :default => false, :null => false
    t.boolean "dispatcher_ready",               :default => false, :null => false
    t.integer "status",                         :default => 0,     :null => false
    t.float   "execute_time",                   :default => 0.0,   :null => false
    t.text    "extended_status",                                   :null => false
  end

  add_index "run_models", ["dll"], :name => "index_run_models_on_dll"
  add_index "run_models", ["run_id"], :name => "index_run_models_on_run_id"
  add_index "run_models", ["run_peer_id"], :name => "index_run_models_on_run_peer_id"

