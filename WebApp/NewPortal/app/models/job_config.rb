################################################################
## JobConfig is the ActiveRecord ORM class to the "JobConfigs" table in the
## Delilah database.

require 'pathname_mods'

class JobConfig < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  
  belongs_to :job
  belongs_to :model
  belongs_to :user
  belongs_to :node

  def self.get_input_file(job_id=1, model_id=1, model_instance=1)
    jc = self.first(:conditions => "job_id = #{job_id} and model_id = #{model_id} and model_instance = #{model_instance}")
    jc.nil? ? nil : Pathname.new(jc.input_file)
  end
  
  def self.find_all_by_job_id(a_job_id)
    self.find(:all, :conditions => "job_id = #{a_job_id}")
  end

end ## end of class JobConfig < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:46 -0500 2010

  create_table "job_configs", :force => true do |t|
    t.integer "job_id",                                        :null => false
    t.integer "node_id",                        :default => 0
    t.integer "model_id",                                      :null => false
    t.integer "model_instance",                 :default => 1, :null => false
    t.string  "cmd_line_param", :limit => 2048
    t.string  "input_file",     :limit => 2048
  end

  add_index "job_configs", ["job_id"], :name => "index_job_configs_on_job_id"
  add_index "job_configs", ["model_id"], :name => "index_job_configs_on_model_id"
  add_index "job_configs", ["node_id"], :name => "index_job_configs_on_node_id"

