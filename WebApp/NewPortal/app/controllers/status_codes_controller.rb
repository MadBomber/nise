class StatusCodesController < ApplicationController
  
  set_tab :status_codes
  
  # GET /status_codes.json
  def index
    @status_codes = StatusCode.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @status_codes }
    end
  end

  # GET /status_codes/1
  # GET /status_codes/1.json
  def show
    @status_code = StatusCode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @status_code }
    end
  end

  # GET /status_codes/new
  # GET /status_codes/new.json
  def new
    @status_code = StatusCode.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @status_code }
    end
  end

  # GET /status_codes/1/edit
  def edit
    @status_code = StatusCode.find(params[:id])
  end

  # POST /status_codes
  # POST /status_codes.json
  def create
    @status_code = StatusCode.new(params[:status_code])

    respond_to do |format|
      if @status_code.save
        format.html { redirect_to @status_code, notice: 'Status code was successfully created.' }
        format.json { render json: @status_code, status: :created, location: @status_code }
      else
        format.html { render action: "new" }
        format.json { render json: @status_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /status_codes/1
  # PUT /status_codes/1.json
  def update
    @status_code = StatusCode.find(params[:id])

    respond_to do |format|
      if @status_code.update_attributes(params[:status_code])
        format.html { redirect_to @status_code, notice: 'Status code was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @status_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /status_codes/1
  # DELETE /status_codes/1.json
  def destroy
    @status_code = StatusCode.find(params[:id])
    @status_code.destroy

    respond_to do |format|
      format.html { redirect_to status_codes_url }
      format.json { head :ok }
    end
  end
end
