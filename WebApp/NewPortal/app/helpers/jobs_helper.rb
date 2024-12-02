module JobsHelper

  require 'IseDatabase_Utilities'

  def show_job_details(job_id)
    JobConfig.find_all_by_job_id(job_id)
  end
  
end
