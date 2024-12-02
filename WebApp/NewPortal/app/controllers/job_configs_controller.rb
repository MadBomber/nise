# TODO: get rid of this controller and associated views; use
#       an 'expand' button on an entry in the Jobs listing
#       to show all the models associated with the Job.

class JobConfigsController < ApplicationController
  
  set_tab :job_configs
  
  # GET /job_configs.json
  def index
    @jobs = Job.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @job_configs }
    end
  end

  # GET /job_configs/1
  # GET /job_configs/1.json
  def show
    @job_config = JobConfig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job_config }
    end
  end
  
  
end
