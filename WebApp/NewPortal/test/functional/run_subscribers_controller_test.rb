require 'test_helper'

class RunSubscribersControllerTest < ActionController::TestCase
  setup do
    @run_subscriber = run_subscribers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:run_subscribers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run_subscriber" do
    assert_difference('RunSubscriber.count') do
      post :create, run_subscriber: @run_subscriber.attributes
    end

    assert_redirected_to run_subscriber_path(assigns(:run_subscriber))
  end

  test "should show run_subscriber" do
    get :show, id: @run_subscriber.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @run_subscriber.to_param
    assert_response :success
  end

  test "should update run_subscriber" do
    put :update, id: @run_subscriber.to_param, run_subscriber: @run_subscriber.attributes
    assert_redirected_to run_subscriber_path(assigns(:run_subscriber))
  end

  test "should destroy run_subscriber" do
    assert_difference('RunSubscriber.count', -1) do
      delete :destroy, id: @run_subscriber.to_param
    end

    assert_redirected_to run_subscribers_path
  end
end
