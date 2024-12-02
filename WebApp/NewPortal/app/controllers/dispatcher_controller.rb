require 'IseDispatcher'
class DispatcherController < ApplicationController

  set_tab :dispatcher
  
  def index
    @dispatchers = RunPeer.find_all_by_peer_key('dispatcher')
  end

  def detail
  end

end
