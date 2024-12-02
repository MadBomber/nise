require 'test_helper'

class RunModelOverridesControllerTest < ActionController::TestCase
  setup do
    @run_model_override = run_model_overrides(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_model_overrides)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_model_override" do
    assert_difference('RunModelOverride.count') do
      post :create, run_model_override: @run_model_override.attributes
    end

    assert_redirected_to run_model_override_path(assigns(:run_model_override))
  end

  test "should show run_model_override" do
    get :show, id: @run_model_override.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_model_override.to_param
    assert_response :success
  end

  test "should update run_model_override" do
    put :update, id: @run_model_override.to_param, run_model_override: @run_model_override.attributes
    assert_redirected_to run_model_override_path(assigns(:run_model_override))
  end

  test "should destroy run_model_override" do
    assert_difference('RunModelOverride.count', -1) do
      delete :destroy, id: @run_model_override.to_param
    end

    assert_redirected_to run_model_overrides_path
  end
end
