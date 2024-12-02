require 'test_helper'

class JobConfigsControllerTest < ActionController::TestCase
  setup do
    @job_config = job_configs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:job_configs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create job_config" do
    assert_difference('JobConfig.count') do
      post :create, job_config: @job_config.attributes
    end

    assert_redirected_to job_config_path(assigns(:job_config))
  end

  test "should show job_config" do
    get :show, id: @job_config.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @job_config.to_param
    assert_response :success
  end

  test "should update job_config" do
    put :update, id: @job_config.to_param, job_config: @job_config.attributes
    assert_redirected_to job_config_path(assigns(:job_config))
  end

  test "should destroy job_config" do
    assert_difference('JobConfig.count', -1) do
      delete :destroy, id: @job_config.to_param
    end

    assert_redirected_to job_configs_path
  end
end
