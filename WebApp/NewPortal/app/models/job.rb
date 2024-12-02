################################################################
## Job is the ActiveRecord ORM class to the "Jobs" table in the
## Delilah database.
##
##  Naming convention: a job is a specific configuration of models whereas
##  a run is an instance of a job.  A job can have many runs whereas a run
##  belongs to only one job.
#

require 'IseRun'

class Job < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG

  has_many :job_configs, :dependent => :delete_all  # :dependent option does not work as expected
  has_many :models, :through => :job_config
  has_many :runs
    
#  belongs_to   :created_by_users, :class_name => User, :foreign_key => "created_by_user_id"
#  belongs_to   :updated_by_users, :class_name => User, :foreign_key => "created_by_user_id"
  
  validates :name,  :presence   => true,
                    :uniqueness => { :case_sensitive => false },
                    :length     => { :maximum => 64 }

#  validates :name,  :allow_blank => false


  def created_by_user
    User.find(created_by_user_id)
  end
  
  def updated_by_user
    User.find(updated_by_user_id)
  end
 

  ###############################################
  ## launch an IseJob
  
  def launch
    $stderr.puts "..... launching IseJob: #{id}} #{name} -- #{description}"
    a = IseRun.new(id)
    a.setup
    a.execute
    return a.run.id
  end
  
  #########################################################
  ## delete an IseJob
  ## Must delete all runs associated with this IseJob first
  
  def delete_job
  
    unless self.runs.empty?
    
      self.job_configs.each do |jc|
        jc.delete
      end

      self.delete
    
    else
      if $verbose or $debug
        $stderr.puts "WARNING: Cannot delete IseJob: #{self.name} - #{self.description}"
        $stderr.puts "         It still has #{self.runs.count} runs in the IseDatabase."
      end
    end
  
  end


end ## end of class Job < DelilahDatabase


__END__
Last Update: Tue Aug 10 14:06:44 -0500 2010

  create_table "jobs", :force => true do |t|
    t.datetime "created_at",                         :null => false
    t.integer  "created_by_user_id",                 :null => false
    t.datetime "updated_at"
    t.integer  "updated_by_user_id"
    t.string   "name",               :limit => 64,   :null => false
    t.string   "desc",               :limit => 1024, :null => false
    t.string   "default_input_dir",  :limit => 2048, :null => false
    t.string   "default_output_dir", :limit => 2048, :null => false
  end

  add_index "jobs", ["name"], :name => "index_jobs_on_name", :unique => true

