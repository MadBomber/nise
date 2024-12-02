require 'test_helper'

class RunModelsControllerTest < ActionController::TestCase
  setup do
    @run_model = run_models(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_models)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_model" do
    assert_difference('RunModel.count') do
      post :create, run_model: @run_model.attributes
    end

    assert_redirected_to run_model_path(assigns(:run_model))
  end

  test "should show run_model" do
    get :show, id: @run_model.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_model.to_param
    assert_response :success
  end

  test "should update run_model" do
    put :update, id: @run_model.to_param, run_model: @run_model.attributes
    assert_redirected_to run_model_path(assigns(:run_model))
  end

  test "should destroy run_model" do
    assert_difference('RunModel.count', -1) do
      delete :destroy, id: @run_model.to_param
    end

    assert_redirected_to run_models_path
  end
end
