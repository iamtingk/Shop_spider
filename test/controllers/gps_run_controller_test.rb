require 'test_helper'

class GpsRunControllerTest < ActionController::TestCase
  test "should get run" do
    get :run
    assert_response :success
  end

  test "should get read" do
    get :read
    assert_response :success
  end

end
