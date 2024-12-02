require 'test_helper'

class NameValuesControllerTest < ActionController::TestCase
  setup do
    @name_value = name_values(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:name_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create name_value" do
    assert_difference('NameValue.count') do
      post :create, name_value: @name_value.attributes
    end

    assert_redirected_to name_value_path(assigns(:name_value))
  end

  test "should show name_value" do
    get :show, id: @name_value.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @name_value.to_param
    assert_response :success
  end

  test "should update name_value" do
    put :update, id: @name_value.to_param, name_value: @name_value.attributes
    assert_redirected_to name_value_path(assigns(:name_value))
  end

  test "should destroy name_value" do
    assert_difference('NameValue.count', -1) do
      delete :destroy, id: @name_value.to_param
    end

    assert_redirected_to name_values_path
  end
end
