#########################################################################
###
##  IseDatabase_Utilities:  database-oriented support methods
##                          required by the IseDatabase.rb file 
##
##	This file may be "required" outside of the IseJCL class stack
##
##  TODO: move some of these methods into the IseDatabase as class methods
#

require 'IseJCL_Utilities'	## support utilities

######################################################################
## Delete a run, its associated peers and the associated GUID database
##
## Delete Sequence:
##  1. RunSubscriber
##  2. RunMessages
##  3. RunPeer
##  4. RunModel
##  5. GuidDatabase
##  6. Output directory
##  7. Run
##
##  TODO: Add some error checking to delete_a_run
#

def delete_a_run(my_run)

  my_run = Run.find(my_run)   if my_run.class.to_s != 'Run'

## 1. delete all run_subscribers associated with this run
  my_run_messages = RunMessage.find_all_by_run_id(my_run.id)
  unless my_run_messages.nil?
    my_run_messages.each do |mrm|
      RunSubscriber.delete_all "run_message_id = #{mrm.id}"
    end
  end

## 2. delete all run_messages associated with this run
  RunMessage.delete_all "run_id = #{my_run.id}"

## 3. delete all run_peers associated with this run
  my_run_models = RunModel.find_all_by_run_id(my_run.id)
  unless my_run_models.nil?
    my_run_models.each do |mrm|
      RunPeer.delete(mrm.run_peer_id)
    end
  end

## 4. delete all run_models associated with this run
  RunModel.delete_all "run_id = #{my_run.id}"

##  5. delete the guid database associated with this run
  IseDatabase.drop_guid_database(my_run.guid)
  
## 6. delete the output directory associated with this run
  begin
    Pathname.new(my_run.output_dir).rmtree
  rescue
  end

## 7. delete this run record
  Run.delete(my_run.id)

end

# CAUTION: only pull the trigger when you know what you are shooting
def delete_all_runs

  all_runs = Run.find(:all)
  
  # SMELL: No user checking to see if this run belogs to this user
  all_runs.each { |a_run| delete_a_run(a_run) }

end





##################################
# List the jobs in the IseDatabase

def list_jobs

  all_jobs = Job.find(:all)

  puts "\nThere are " + all_jobs.length.to_s + " IseJobs defined in the IseDatabase:"
  all_jobs.each_index do |x|
    puts "\t" + all_jobs[x].id.to_s + ") #{all_jobs[x].name} -- #{all_jobs[x].description}"
  end
  puts

end

##################################
# List the models in the IseDatabase

def list_models

  all_models = Model.find(:all)

  puts "\nThere are " + all_models.length.to_s + " IseModels defined in the IseDatabase:"
  all_models.each_index do |x|
    puts "\t" + all_models[x].id.to_s + ") #{all_models[x].name} -- #{all_models[x].description}"
  end
  puts

end



#########################################
# List the jobs in the Samson IseDatabase

def list_all_jobs

  all_jobs = Job.find(:all)

  puts "\nThere are " + all_jobs.length.to_s + " IseJobs defined in the IseDatabase:"
  max_name_length = 0
  all_jobs.each_index { |x| all_jobs[x].name.length > max_name_length ? max_name_length = all_jobs[x].name.length : nil}
  
  all_jobs.each_index do |x|
    printf "\t%3d) %-#{max_name_length}s  %s\n", all_jobs[x].id, all_jobs[x].name, all_jobs[x].description
  end
  
  puts
  
  return all_jobs.length

end



#########################################
# List a job in the Samson IseDatabase

def list_job (which_job, full = false)

  my_rpt = ""

  parm_type = which_job.class.to_s
  
  if    parm_type == "Fixnum"
    begin
      a_job = Job.find(which_job)
    rescue
      a_job = nil
    end
  elsif parm_type == "String"
    a_job = Job.find_by_name(which_job)
  elsif parm_type == "IseJob"
    which_job_str = which_job.name
    which_job     = which_job_str
    a_job = Job.find_by_name(which_job)
  else
    ERROR(["Expected the parameter to be either the job id, name or an IseJob object.",
            "The parameter that was passed is of an unsupported class: #{parm_type}"])
    return nil
  end

  unless a_job
  
    ERROR(["Job #{which_job} was not found in the IseDatabase"])
    return nil
    
  end

  
  c_user = User.find(a_job.created_by_user_id)
  if a_job.created_by_user_id == a_job.updated_by_user_id
    u_user = c_user
  else
    u_user = User.find(a_job.updated_by_user_id)
  end
  
  my_rpt += "\n" +
  my_rpt += "\n" + "Job Id: #{a_job.id}"
  my_rpt += "\n" + "  Name: #{a_job.name}"
  my_rpt += "\n" + "  Desc: #{a_job.description}"
  my_rpt += "\n"
  my_rpt += "\n" + "Created: #{a_job.created_at}"
  my_rpt += "\n" + "     by: #{c_user.name} (#{c_user.login}) #{c_user.phone_number} / #{c_user.email}"
  my_rpt += "\n" + "Updated: #{a_job.updated_at}"
  my_rpt += "\n" + "     by: #{u_user.name} (#{u_user.login}) #{u_user.phone_number} / #{u_user.email}"
  my_rpt += "\n"
  my_rpt += "\n" + "Default input directory:  #{a_job.default_input_dir}"
  my_rpt += "\n" + "Default output directory: #{a_job.default_output_dir}"
  my_rpt += "\n"
  my_rpt += "\n" + "Message Router: #{a_job.router}"
  my_rpt += "\n"
  my_rpt += "\n" + "The following IseModels compose this IseJob:"
  my_rpt += "\n"
  
  a_job_config = JobConfig.find(:all, :conditions => "job_id = #{a_job.id}")
  
  the_models = Hash.new
  last_model_id = 0
  
  a_job_config.each_index do |x|
    unless last_model_id == a_job_config[x].model_id
      last_model_id = a_job_config[x].model_id
      the_models[a_job_config[x].model.name] = a_job_config[x].model.description
    end
  end
  
  max_model_name_length = 0

  the_models.each_key do |k|
    unless k.length <= max_model_name_length
      max_model_name_length = k.length
    end
  end
  
  my_rpt += sprintf "\t%-#{max_model_name_length}s %s\n", "Name", "Description"
  the_models.each_key do |k|
    my_rpt += sprintf "\t%-#{max_model_name_length}s %s\n", k, the_models[k]
  end
  
  my_rpt += "\n" + "\nConfiguration Details for each IseModel in this IseJob"
  my_rpt += "\n" +   "======================================================"
  
#  puts a_job_config.columnized
  
  last_model_id = 0
  a_job_config.each_index do |x|
    unless last_model_id == a_job_config[x].model_id
      last_model_id = a_job_config[x].model_id
      my_rpt += "\n"
      my_rpt += "\n" + "  IseModel: " + a_job_config[x].model.name
      my_rpt += "\n" + "      Desc: " + a_job_config[x].model.description
      my_rpt += "\n" + "  Location: " + a_job_config[x].model.location
      my_rpt += "\n" + "       DLL: " + a_job_config[x].model.dll
      
      rq = a_job_config[x].required
      my_rpt += "\n" + "  Required: #{rq}#{rq ? '' : ' (optional; not managed by a controlling model)'}"
      
      my_rpt += "\n" + "Msg Router: " + a_job_config[x].model.router
      my_rpt += "\n" + "  Platform: " + a_job_config[x].model.platform.name + " -- " + a_job_config[x].model.platform.description
      my_rpt += "\n" + "   Created: #{a_job_config[x].model.created_at} by: " + User.find(a_job_config[x].model.created_by_user_id).name + " (" + User.find(a_job_config[x].model.created_by_user_id).login+ ")"
      my_rpt += "\n" + "   Updated: #{a_job_config[x].model.updated_at} by: " + User.find(a_job_config[x].model.updated_by_user_id).name + " (" + User.find(a_job_config[x].model.updated_by_user_id).login+ ")"
      my_rpt += "\n" + "  Instance:" + "\n"
    end

    my_rpt += "\t#{a_job_config[x].model_instance})"
    my_rpt += " IseDrone: #{a_job_config[x].node.name}"
    my_rpt += " CmdLineParms: '#{a_job_config[x].cmd_line_param}'"
    my_rpt += " InputFile: #{a_job_config[x].input_file}\n"
     
  end

  if $ISE_RUNNING_ON_RAILS
    return my_rpt
  else
    puts my_rpt
    puts
    return nil
  end

end  ## end of list_job

  
############################################################
## retryable
#
# Options:
# * :tries - Number of retries to perform. Defaults to 1.
# * :on - The Exception on which a retry will be performed. Defaults to Exception, which retries on any Exception.
#
# Example
# =======
#   retryable(:tries => 1, :on => OpenURI::HTTPError) do
#     # your code here
#   end
#
def retryable(options = {}, &block)
  opts = { :tries => 1, :on => Exception }.merge(options)

  retry_exception, retries = opts[:on], opts[:tries]

  begin
    return yield
  rescue retry_exception
    retry if (retries -= 1) > 0
  end

  yield
end


############################################################
##

def valid_host?(my_host)
  
  good_host = get_node_by_host(my_host)
  
  return (not good_host.nil?)
    
end ## end of def valid_host?(my_host)




