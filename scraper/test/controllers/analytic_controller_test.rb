require "test_helper"

class AnalyticControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get analytic_index_url
    assert_response :success
  end
end
