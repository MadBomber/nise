require 'test_helper'

class RunPeersControllerTest < ActionController::TestCase
  setup do
    @run_peer = run_peers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_peers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_peer" do
    assert_difference('RunPeer.count') do
      post :create, run_peer: @run_peer.attributes
    end

    assert_redirected_to run_peer_path(assigns(:run_peer))
  end

  test "should show run_peer" do
    get :show, id: @run_peer.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_peer.to_param
    assert_response :success
  end

  test "should update run_peer" do
    put :update, id: @run_peer.to_param, run_peer: @run_peer.attributes
    assert_redirected_to run_peer_path(assigns(:run_peer))
  end

  test "should destroy run_peer" do
    assert_difference('RunPeer.count', -1) do
      delete :destroy, id: @run_peer.to_param
    end

    assert_redirected_to run_peers_path
  end
end
