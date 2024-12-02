class DebugFlagsController < ApplicationController
  
  set_tab :debug_flags
  
  # GET /debug_flags.json
  def index
    @debug_flags = DebugFlag.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @debug_flags }
    end
  end

  # GET /debug_flags/1
  # GET /debug_flags/1.json
  def show
    @debug_flag = DebugFlag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @debug_flag }
    end
  end

  # GET /debug_flags/new
  # GET /debug_flags/new.json
  def new
    @debug_flag = DebugFlag.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @debug_flag }
    end
  end

  # GET /debug_flags/1/edit
  def edit
    @debug_flag = DebugFlag.find(params[:id])
  end

  # POST /debug_flags
  # POST /debug_flags.json
  def create
    @debug_flag = DebugFlag.new(params[:debug_flag])

    respond_to do |format|
      if @debug_flag.save
        format.html { redirect_to @debug_flag, notice: 'Debug flag was successfully created.' }
        format.json { render json: @debug_flag, status: :created, location: @debug_flag }
      else
        format.html { render action: "new" }
        format.json { render json: @debug_flag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /debug_flags/1
  # PUT /debug_flags/1.json
  def update
    @debug_flag = DebugFlag.find(params[:id])

    respond_to do |format|
      if @debug_flag.update_attributes(params[:debug_flag])
        format.html { redirect_to @debug_flag, notice: 'Debug flag was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @debug_flag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /debug_flags/1
  # DELETE /debug_flags/1.json
  def destroy
    @debug_flag = DebugFlag.find(params[:id])
    @debug_flag.destroy

    respond_to do |format|
      format.html { redirect_to debug_flags_url }
      format.json { head :ok }
    end
  end
end
