class RunPeersController < ApplicationController
  
  set_tab :run_peers
  
  # GET /run_peers.json
  def index
    @run_peers = RunPeer.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @run_peers }
    end
  end

  # GET /run_peers/1
  # GET /run_peers/1.json
  def show
    @run_peer = RunPeer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @run_peer }
    end
  end

  # GET /run_peers/new
  # GET /run_peers/new.json
  def new
    @run_peer = RunPeer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @run_peer }
    end
  end

  # GET /run_peers/1/edit
  def edit
    @run_peer = RunPeer.find(params[:id])
  end

  # POST /run_peers
  # POST /run_peers.json
  def create
    @run_peer = RunPeer.new(params[:run_peer])

    respond_to do |format|
      if @run_peer.save
        format.html { redirect_to @run_peer, notice: 'Run peer was successfully created.' }
        format.json { render json: @run_peer, status: :created, location: @run_peer }
      else
        format.html { render action: "new" }
        format.json { render json: @run_peer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /run_peers/1
  # PUT /run_peers/1.json
  def update
    @run_peer = RunPeer.find(params[:id])

    respond_to do |format|
      if @run_peer.update_attributes(params[:run_peer])
        format.html { redirect_to @run_peer, notice: 'Run peer was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @run_peer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /run_peers/1
  # DELETE /run_peers/1.json
  def destroy
    @run_peer = RunPeer.find(params[:id])
    @run_peer.destroy

    respond_to do |format|
      format.html { redirect_to run_peers_url }
      format.json { head :ok }
    end
  end
end
