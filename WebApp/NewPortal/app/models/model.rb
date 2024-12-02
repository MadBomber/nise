################################################################
## Model is the ActiveRecord ORM class to the "Models" table in the
## Delilah database.

class Model < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  has_many    :job_configs
  has_many    :jobs,        :through => :job_config
  belongs_to  :platform
  has_many    :run_model_overrides
  has_many    :runs                   ## only "master" models are in the runs record

end ## end of class Model < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:50 -0500 2010

  create_table "models", :force => true do |t|
    t.integer  "node_id",                            :default => 0
    t.integer  "platform_id",                        :default => 1,  :null => false
    t.datetime "created_at",                                         :null => false
    t.integer  "created_by_user_id",                                 :null => false
    t.datetime "updated_at"
    t.integer  "updated_by_user_id"
    t.string   "name",               :limit => 64,                   :null => false
    t.string   "desc",               :limit => 1024,                 :null => false
    t.string   "location",           :limit => 2048,                 :null => false
    t.string   "dll",                :limit => 80,   :default => "", :null => false
  end

  add_index "models", ["name"], :name => "index_models_on_name", :unique => true

