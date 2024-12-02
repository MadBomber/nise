class NameValuesController < ApplicationController

  set_tab :name_values
  
  # GET /name_values.json
  def index
    @name_values = NameValue.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @name_values }
    end
  end

  # GET /name_values/1
  # GET /name_values/1.json
  def show
    @name_value = NameValue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @name_value }
    end
  end

  # GET /name_values/new
  # GET /name_values/new.json
  def new
    @name_value = NameValue.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @name_value }
    end
  end

  # GET /name_values/1/edit
  def edit
    @name_value = NameValue.find(params[:id])
  end

  # POST /name_values
  # POST /name_values.json
  def create
    @name_value = NameValue.new(params[:name_value])

    respond_to do |format|
      if @name_value.save
        format.html { redirect_to @name_value, notice: 'Name value was successfully created.' }
        format.json { render json: @name_value, status: :created, location: @name_value }
      else
        format.html { render action: "new" }
        format.json { render json: @name_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /name_values/1
  # PUT /name_values/1.json
  def update
    @name_value = NameValue.find(params[:id])

    respond_to do |format|
      if @name_value.update_attributes(params[:name_value])
        format.html { redirect_to @name_value, notice: 'Name value was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @name_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /name_values/1
  # DELETE /name_values/1.json
  def destroy
    @name_value = NameValue.find(params[:id])
    @name_value.destroy

    respond_to do |format|
      format.html { redirect_to name_values_url }
      format.json { head :ok }
    end
  end
end
