class CreateJobConfigs < ActiveRecord::Migration
  def change
    create_table :job_configs do |t|
      t.boolean :required,                       :default => true, :null => false
      t.integer :job_id,                                           :null => false
      t.integer :node_id,                        :default => 0
      t.integer :model_id,                                         :null => false
      t.integer :model_instance,                 :default => 1,    :null => false
      t.string  :cmd_line_param, :limit => 2048
      t.string  :input_file,     :limit => 2048
    end

    add_index "job_configs", ["job_id"],   :name => "index_job_configs_on_job_id"
    add_index "job_configs", ["model_id"], :name => "index_job_configs_on_model_id"
    add_index "job_configs", ["node_id"],  :name => "index_job_configs_on_node_id"

  end
end
