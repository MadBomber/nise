require 'test_helper'

class StatusCodesControllerTest < ActionController::TestCase
  setup do
    @status_code = status_codes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:status_codes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create status_code" do
    assert_difference('StatusCode.count') do
      post :create, status_code: @status_code.attributes
    end

    assert_redirected_to status_code_path(assigns(:status_code))
  end

  test "should show status_code" do
    get :show, id: @status_code.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @status_code.to_param
    assert_response :success
  end

  test "should update status_code" do
    put :update, id: @status_code.to_param, status_code: @status_code.attributes
    assert_redirected_to status_code_path(assigns(:status_code))
  end

  test "should destroy status_code" do
    assert_difference('StatusCode.count', -1) do
      delete :destroy, id: @status_code.to_param
    end

    assert_redirected_to status_codes_path
  end
end
