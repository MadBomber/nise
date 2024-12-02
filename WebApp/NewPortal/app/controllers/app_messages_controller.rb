class AppMessagesController < ApplicationController
  
  set_tab :app_messages
  
  # GET /app_messages.json
  def index
    @app_messages = AppMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @app_messages }
    end
  end

  # GET /app_messages/1
  # GET /app_messages/1.json
  def show
    @app_message = AppMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @app_message }
    end
  end

  # GET /app_messages/new
  # GET /app_messages/new.json
  def new
    @app_message = AppMessage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @app_message }
    end
  end

  # GET /app_messages/1/edit
  def edit
    @app_message = AppMessage.find(params[:id])
  end

  # POST /app_messages
  # POST /app_messages.json
  def create
    @app_message = AppMessage.new(params[:app_message])

    respond_to do |format|
      if @app_message.save
        format.html { redirect_to @app_message, notice: 'App message was successfully created.' }
        format.json { render json: @app_message, status: :created, location: @app_message }
      else
        format.html { render action: "new" }
        format.json { render json: @app_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /app_messages/1
  # PUT /app_messages/1.json
  def update
    @app_message = AppMessage.find(params[:id])

    respond_to do |format|
      if @app_message.update_attributes(params[:app_message])
        format.html { redirect_to @app_message, notice: 'App message was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @app_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app_messages/1
  # DELETE /app_messages/1.json
  def destroy
    @app_message = AppMessage.find(params[:id])
    @app_message.destroy

    respond_to do |format|
      format.html { redirect_to app_messages_url }
      format.json { head :ok }
    end
  end
end
