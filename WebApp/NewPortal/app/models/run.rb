################################################################
## Run is the ActiveRecord ORM class to the "Runs" table in the
## Delilah database.
##
##  Naming convention: a run is a specific runtime instance of a job.  The
##  job is the static configuration of a collection of models.
#

require 'IseArchive'
  
class Run < ActiveRecord::Base
#  self.establish_connection $DELILAH_CONFIG
  

  belongs_to :user
  belongs_to :job
  belongs_to :run_peer    ## The "Master" model for the run

  has_many   :run_externals
  has_many   :run_models
  has_many   :run_messages
  has_many   :run_subscribers
  has_many   :run_model_overrides

  def archive
  
    $stderr.puts ".......archiving run #{id}"
  
    IseArchive.run(id)
    return false    ## TODO: The IseArchive class needs more substance
  end

 
  ################################################
  ## Quicky status report for all runs
  
  def self.status_report
  # TODO: Make the Run.status_report look pretty
    all_runs = self.count
    if all_runs > 0
      puts "There are #{all_runs} runs in the IseDatabase"
      puts
      Run.includes(:job, :user).each do |a_run|
        puts "Run ID: #{a_run.id})\tStatus: #{a_run.status}   GUID: #{a_run.guid}"
        puts "\tJob ID: #{a_run.job_id}) #{a_run.job.name} - #{a_run.job.description}"
        puts "\tTime:   #{a_run.created_at}  .. #{a_run.terminated_at}"
        puts "\tUser:   #{a_run.user_id}} #{a_run.user.login} -- #{a_run.user.name} (#{a_run.user.phone_number})"
        puts
      end
    else
      puts "There are no runs in the IseDatabase."
    end
    return nil
  end

end ## end of class Run < ActiveRecord::Base


__END__
Last Update: Tue Aug 10 14:06:44 -0500 2010

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
  end

  add_index "runs", ["guid"], :name => "index_runs_on_guid", :unique => true
  add_index "runs", ["job_id"], :name => "index_runs_on_job_id"
  add_index "runs", ["user_id"], :name => "index_runs_on_user_id"

