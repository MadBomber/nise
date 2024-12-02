require 'test_helper'

class AppMessagesControllerTest < ActionController::TestCase
  setup do
    @app_message = app_messages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:app_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create app_message" do
    assert_difference('AppMessage.count') do
      post :create, app_message: @app_message.attributes
    end

    assert_redirected_to app_message_path(assigns(:app_message))
  end

  test "should show app_message" do
    get :show, id: @app_message.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @app_message.to_param
    assert_response :success
  end

  test "should update app_message" do
    put :update, id: @app_message.to_param, app_message: @app_message.attributes
    assert_redirected_to app_message_path(assigns(:app_message))
  end

  test "should destroy app_message" do
    assert_difference('AppMessage.count', -1) do
      delete :destroy, id: @app_message.to_param
    end

    assert_redirected_to app_messages_path
  end
end
