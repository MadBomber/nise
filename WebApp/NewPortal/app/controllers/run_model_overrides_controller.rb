class RunModelOverridesController < ApplicationController
  
  set_tab :rmo        # run_model_overrides
  
  # GET /run_model_overrides.json
  def index
    @run_model_overrides = RunModelOverride.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @run_model_overrides }
    end
  end

  # GET /run_model_overrides/1
  # GET /run_model_overrides/1.json
  def show
    @run_model_override = RunModelOverride.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run_model_override }
    end
  end

  # GET /run_model_overrides/new
  # GET /run_model_overrides/new.json
  def new
    @run_model_override = RunModelOverride.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_model_override }
    end
  end

  # GET /run_model_overrides/1/edit
  def edit
    @run_model_override = RunModelOverride.find(params[:id])
  end

  # POST /run_model_overrides
  # POST /run_model_overrides.json
  def create
    @run_model_override = RunModelOverride.new(params[:run_model_override])

    respond_to do |format|
      if @run_model_override.save
        format.html { redirect_to @run_model_override, notice: 'Run model override was successfully created.' }
        format.json { render json: @run_model_override, status: :created, location: @run_model_override }
      else
        format.html { render action: "new" }
        format.json { render json: @run_model_override.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /run_model_overrides/1
  # PUT /run_model_overrides/1.json
  def update
    @run_model_override = RunModelOverride.find(params[:id])

    respond_to do |format|
      if @run_model_override.update_attributes(params[:run_model_override])
        format.html { redirect_to @run_model_override, notice: 'Run model override was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @run_model_override.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /run_model_overrides/1
  # DELETE /run_model_overrides/1.json
  def destroy
    @run_model_override = RunModelOverride.find(params[:id])
    @run_model_override.destroy

    respond_to do |format|
      format.html { redirect_to run_model_overrides_url }
      format.json { head :ok }
    end
  end
end
