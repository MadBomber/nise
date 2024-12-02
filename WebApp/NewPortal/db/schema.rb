# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110901033951) do

  create_table "app_messages", :force => true do |t|
    t.string   "app_message_key"
    t.text     "description"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "app_messages", ["app_message_key"], :name => "index_app_messages_on_app_message_key", :unique => true

  create_table "debug_flags", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "dispatcher_stats", :force => true do |t|
    t.integer  "run_peer_id",                 :default => 0,   :null => false
    t.integer  "n_bytes",                     :default => 0,   :null => false
    t.integer  "n_msgs",                      :default => 0,   :null => false
    t.float    "mean_alive",                  :default => 0.0, :null => false
    t.float    "stddev_alive",                :default => 0.0, :null => false
    t.float    "min_time_alive",              :default => 0.0, :null => false
    t.float    "max_time_alive",              :default => 0.0, :null => false
    t.string   "direction",      :limit => 1,                  :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "dispatcher_stats", ["run_peer_id", "direction"], :name => "compound_index", :unique => true
  add_index "dispatcher_stats", ["run_peer_id"], :name => "index_dispatcher_stats_on_run_peer_id"

  create_table "job_configs", :force => true do |t|
    t.boolean "required",                       :default => true, :null => false
    t.integer "job_id",                                           :null => false
    t.integer "node_id",                        :default => 0
    t.integer "model_id",                                         :null => false
    t.integer "model_instance",                 :default => 1,    :null => false
    t.string  "cmd_line_param", :limit => 2048
    t.string  "input_file",     :limit => 2048
  end

  add_index "job_configs", ["job_id"], :name => "index_job_configs_on_job_id"
  add_index "job_configs", ["model_id"], :name => "index_job_configs_on_model_id"
  add_index "job_configs", ["node_id"], :name => "index_job_configs_on_node_id"

  create_table "jobs", :force => true do |t|
    t.integer  "created_by_user_id", :null => false
    t.integer  "updated_by_user_id"
    t.string   "name"
    t.string   "description"
    t.string   "default_input_dir"
    t.string   "default_output_dir"
    t.string   "router"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "jobs", ["name"], :name => "index_jobs_on_name", :unique => true

  create_table "models", :force => true do |t|
    t.integer  "node_id"
    t.integer  "platform_id"
    t.integer  "created_by_user_id", :null => false
    t.integer  "updated_by_user_id"
    t.string   "name"
    t.string   "description"
    t.string   "location"
    t.string   "dll"
    t.string   "router"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "name_values", :force => true do |t|
    t.string   "name"
    t.text     "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "nodes", :force => true do |t|
    t.integer  "platform_id"
    t.integer  "status"
    t.string   "name"
    t.string   "description"
    t.string   "ip_address"
    t.string   "fqdn"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "platforms", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "lib_prefix"
    t.string   "lib_suffix"
    t.string   "lib_path_name"
    t.string   "lib_path_sep"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "run_externals", :force => true do |t|
    t.integer  "run_id",     :default => 0, :null => false
    t.integer  "node_id",    :default => 0, :null => false
    t.integer  "pid",        :default => 0, :null => false
    t.integer  "status",     :default => 0, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.text     "path",                      :null => false
  end

  add_index "run_externals", ["node_id"], :name => "index_run_externals_on_node_id"
  add_index "run_externals", ["run_id"], :name => "index_run_externals_on_run_id"

  create_table "run_messages", :force => true do |t|
    t.integer "run_id",         :default => 0, :null => false
    t.integer "app_message_id", :default => 0, :null => false
    t.integer "ref_count",      :default => 0, :null => false
  end

  add_index "run_messages", ["app_message_id"], :name => "index_run_messages_on_app_message_id"
  add_index "run_messages", ["run_id", "app_message_id"], :name => "compound_index", :unique => true
  add_index "run_messages", ["run_id"], :name => "index_run_messages_on_run_id"

  create_table "run_model_overrides", :force => true do |t|
    t.integer  "run_id"
    t.integer  "user_id"
    t.integer  "model_id"
    t.integer  "instance"
    t.string   "cmd_line_param"
    t.string   "debug_flags"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

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

  create_table "run_peers", :force => true do |t|
    t.integer  "node_id",                    :default => 0
    t.integer  "pid",                        :default => 0,  :null => false
    t.integer  "control_port",               :default => 0,  :null => false
    t.integer  "status",                     :default => 0,  :null => false
    t.string   "peer_key",     :limit => 32, :default => "", :null => false
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  add_index "run_peers", ["node_id"], :name => "index_run_peers_on_node_id"
  add_index "run_peers", ["peer_key"], :name => "index_run_peers_on_peer_key"

  create_table "run_subscribers", :force => true do |t|
    t.integer  "run_message_id", :default => 0, :null => false
    t.integer  "instance",       :default => 0, :null => false
    t.integer  "run_peer_id",    :default => 0, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "run_subscribers", ["run_message_id"], :name => "index_run_subscribers_on_run_message_id"
  add_index "run_subscribers", ["run_peer_id"], :name => "index_run_subscribers_on_run_peer_id"

  create_table "runs", :force => true do |t|
    t.integer  "job_id",                                              :null => false
    t.integer  "run_peer_id",                         :default => 0,  :null => false
    t.integer  "user_id",                                             :null => false
    t.integer  "notification_method",                                 :null => false
    t.datetime "created_at",                                          :null => false
    t.datetime "terminated_at"
    t.integer  "status",                                              :null => false
    t.string   "debug_flags",         :limit => 64,   :default => "", :null => false
    t.string   "guid",                :limit => 36,                   :null => false
    t.string   "input_dir",           :limit => 2048,                 :null => false
    t.string   "output_dir",          :limit => 2048,                 :null => false
    t.datetime "updated_at",                                          :null => false
  end

  add_index "runs", ["guid"], :name => "index_runs_on_guid", :unique => true
  add_index "runs", ["job_id"], :name => "index_runs_on_job_id"
  add_index "runs", ["user_id"], :name => "index_runs_on_user_id"

  create_table "status_codes", :force => true do |t|
    t.integer  "code"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "status_codes", ["code"], :name => "index_status_codes_on_code", :unique => true

  create_table "users", :force => true do |t|
    t.boolean  "admin"
    t.string   "login"
    t.string   "name"
    t.string   "email"
    t.string   "phone_number"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

end
