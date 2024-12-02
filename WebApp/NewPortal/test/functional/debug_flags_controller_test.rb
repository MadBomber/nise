require 'test_helper'

class DebugFlagsControllerTest < ActionController::TestCase
  setup do
    @debug_flag = debug_flags(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:debug_flags)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create debug_flag" do
    assert_difference('DebugFlag.count') do
      post :create, debug_flag: @debug_flag.attributes
    end

    assert_redirected_to debug_flag_path(assigns(:debug_flag))
  end

  test "should show debug_flag" do
    get :show, id: @debug_flag.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @debug_flag.to_param
    assert_response :success
  end

  test "should update debug_flag" do
    put :update, id: @debug_flag.to_param, debug_flag: @debug_flag.attributes
    assert_redirected_to debug_flag_path(assigns(:debug_flag))
  end

  test "should destroy debug_flag" do
    assert_difference('DebugFlag.count', -1) do
      delete :destroy, id: @debug_flag.to_param
    end

    assert_redirected_to debug_flags_path
  end
end
