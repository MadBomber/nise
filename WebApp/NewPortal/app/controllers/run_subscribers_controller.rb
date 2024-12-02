class RunSubscribersController < ApplicationController
  
  set_tab :run_subscribers
  
  # GET /run_subscribers.json
  def index
    @run_subscribers = RunSubscriber.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @run_subscribers }
    end
  end

  # GET /run_subscribers/1
  # GET /run_subscribers/1.json
  def show
    @run_subscriber = RunSubscriber.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run_subscriber }
    end
  end

  # GET /run_subscribers/new
  # GET /run_subscribers/new.json
  def new
    @run_subscriber = RunSubscriber.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_subscriber }
    end
  end

  # GET /run_subscribers/1/edit
  def edit
    @run_subscriber = RunSubscriber.find(params[:id])
  end

  # POST /run_subscribers
  # POST /run_subscribers.json
  def create
    @run_subscriber = RunSubscriber.new(params[:run_subscriber])

    respond_to do |format|
      if @run_subscriber.save
        format.html { redirect_to @run_subscriber, notice: 'Run subscriber was successfully created.' }
        format.json { render json: @run_subscriber, status: :created, location: @run_subscriber }
      else
        format.html { render action: "new" }
        format.json { render json: @run_subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /run_subscribers/1
  # PUT /run_subscribers/1.json
  def update
    @run_subscriber = RunSubscriber.find(params[:id])

    respond_to do |format|
      if @run_subscriber.update_attributes(params[:run_subscriber])
        format.html { redirect_to @run_subscriber, notice: 'Run subscriber was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @run_subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /run_subscribers/1
  # DELETE /run_subscribers/1.json
  def destroy
    @run_subscriber = RunSubscriber.find(params[:id])
    @run_subscriber.destroy

    respond_to do |format|
      format.html { redirect_to run_subscribers_url }
      format.json { head :ok }
    end
  end
end
