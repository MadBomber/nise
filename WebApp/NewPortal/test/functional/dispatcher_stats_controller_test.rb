require 'test_helper'

class DispatcherStatsControllerTest < ActionController::TestCase
  setup do
    @dispatcher_stat = dispatcher_stats(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dispatcher_stats)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dispatcher_stat" do
    assert_difference('DispatcherStat.count') do
      post :create, dispatcher_stat: @dispatcher_stat.attributes
    end

    assert_redirected_to dispatcher_stat_path(assigns(:dispatcher_stat))
  end

  test "should show dispatcher_stat" do
    get :show, id: @dispatcher_stat.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dispatcher_stat.to_param
    assert_response :success
  end

  test "should update dispatcher_stat" do
    put :update, id: @dispatcher_stat.to_param, dispatcher_stat: @dispatcher_stat.attributes
    assert_redirected_to dispatcher_stat_path(assigns(:dispatcher_stat))
  end

  test "should destroy dispatcher_stat" do
    assert_difference('DispatcherStat.count', -1) do
      delete :destroy, id: @dispatcher_stat.to_param
    end

    assert_redirected_to dispatcher_stats_path
  end
end
