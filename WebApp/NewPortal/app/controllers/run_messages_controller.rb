class RunMessagesController < ApplicationController
  
  set_tab :run_messages
  
  # GET /run_messages.json
  def index
    @run_messages = RunMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @run_messages }
    end
  end

  # GET /run_messages/1
  # GET /run_messages/1.json
  def show
    @run_message = RunMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run_message }
    end
  end

  # GET /run_messages/new
  # GET /run_messages/new.json
  def new
    @run_message = RunMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_message }
    end
  end

  # GET /run_messages/1/edit
  def edit
    @run_message = RunMessage.find(params[:id])
  end

  # POST /run_messages
  # POST /run_messages.json
  def create
    @run_message = RunMessage.new(params[:run_message])

    respond_to do |format|
      if @run_message.save
        format.html { redirect_to @run_message, notice: 'Run message was successfully created.' }
        format.json { render json: @run_message, status: :created, location: @run_message }
      else
        format.html { render action: "new" }
        format.json { render json: @run_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /run_messages/1
  # PUT /run_messages/1.json
  def update
    @run_message = RunMessage.find(params[:id])

    respond_to do |format|
      if @run_message.update_attributes(params[:run_message])
        format.html { redirect_to @run_message, notice: 'Run message was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @run_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /run_messages/1
  # DELETE /run_messages/1.json
  def destroy
    @run_message = RunMessage.find(params[:id])
    @run_message.destroy

    respond_to do |format|
      format.html { redirect_to run_messages_url }
      format.json { head :ok }
    end
  end
end
