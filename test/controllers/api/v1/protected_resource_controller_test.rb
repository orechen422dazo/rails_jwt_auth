require "test_helper"

class Api::V1::ProtectedResourceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_protected_resource_index_url
    assert_response :success
  end
end
