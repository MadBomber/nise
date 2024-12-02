class DispatcherStatsController < ApplicationController
  
  set_tab :dispatcher_stats
  
  # GET /dispatcher_stats.json
  def index
    @dispatcher_stats = DispatcherStat.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @dispatcher_stats }
    end
  end

  # GET /dispatcher_stats/1
  # GET /dispatcher_stats/1.json
  def show
    @dispatcher_stat = DispatcherStat.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @dispatcher_stat }
    end
  end

  # GET /dispatcher_stats/new
  # GET /dispatcher_stats/new.json
  def new
    @dispatcher_stat = DispatcherStat.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dispatcher_stat }
    end
  end

  # GET /dispatcher_stats/1/edit
  def edit
    @dispatcher_stat = DispatcherStat.find(params[:id])
  end

  # POST /dispatcher_stats
  # POST /dispatcher_stats.json
  def create
    @dispatcher_stat = DispatcherStat.new(params[:dispatcher_stat])

    respond_to do |format|
      if @dispatcher_stat.save
        format.html { redirect_to @dispatcher_stat, notice: 'Dispatcher stat was successfully created.' }
        format.json { render json: @dispatcher_stat, status: :created, location: @dispatcher_stat }
      else
        format.html { render action: "new" }
        format.json { render json: @dispatcher_stat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /dispatcher_stats/1
  # PUT /dispatcher_stats/1.json
  def update
    @dispatcher_stat = DispatcherStat.find(params[:id])

    respond_to do |format|
      if @dispatcher_stat.update_attributes(params[:dispatcher_stat])
        format.html { redirect_to @dispatcher_stat, notice: 'Dispatcher stat was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @dispatcher_stat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dispatcher_stats/1
  # DELETE /dispatcher_stats/1.json
  def destroy
    @dispatcher_stat = DispatcherStat.find(params[:id])
    @dispatcher_stat.destroy

    respond_to do |format|
      format.html { redirect_to dispatcher_stats_url }
      format.json { head :ok }
    end
  end
end
