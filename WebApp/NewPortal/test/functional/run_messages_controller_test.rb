require 'test_helper'

class RunMessagesControllerTest < ActionController::TestCase
  setup do
    @run_message = run_messages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_message" do
    assert_difference('RunMessage.count') do
      post :create, run_message: @run_message.attributes
    end

    assert_redirected_to run_message_path(assigns(:run_message))
  end

  test "should show run_message" do
    get :show, id: @run_message.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_message.to_param
    assert_response :success
  end

  test "should update run_message" do
    put :update, id: @run_message.to_param, run_message: @run_message.attributes
    assert_redirected_to run_message_path(assigns(:run_message))
  end

  test "should destroy run_message" do
    assert_difference('RunMessage.count', -1) do
      delete :destroy, id: @run_message.to_param
    end

    assert_redirected_to run_messages_path
  end
end
