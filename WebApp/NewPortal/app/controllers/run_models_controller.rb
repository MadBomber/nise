class RunModelsController < ApplicationController
  
  set_tab :run_models
  
  # GET /run_models.json
  def index
    @run_models = RunModel.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @run_models }
    end
  end

  # GET /run_models/1
  # GET /run_models/1.json
  def show
    @run_model = RunModel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run_model }
    end
  end

  # GET /run_models/new
  # GET /run_models/new.json
  def new
    @run_model = RunModel.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_model }
    end
  end

  # GET /run_models/1/edit
  def edit
    @run_model = RunModel.find(params[:id])
  end

  # POST /run_models
  # POST /run_models.json
  def create
    @run_model = RunModel.new(params[:run_model])

    respond_to do |format|
      if @run_model.save
        format.html { redirect_to @run_model, notice: 'Run model was successfully created.' }
        format.json { render json: @run_model, status: :created, location: @run_model }
      else
        format.html { render action: "new" }
        format.json { render json: @run_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /run_models/1
  # PUT /run_models/1.json
  def update
    @run_model = RunModel.find(params[:id])

    respond_to do |format|
      if @run_model.update_attributes(params[:run_model])
        format.html { redirect_to @run_model, notice: 'Run model was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @run_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /run_models/1
  # DELETE /run_models/1.json
  def destroy
    @run_model = RunModel.find(params[:id])
    @run_model.destroy

    respond_to do |format|
      format.html { redirect_to run_models_url }
      format.json { head :ok }
    end
  end
end
