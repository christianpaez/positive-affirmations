require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  test "returns a random quote" do
    get quotes_random_url
    assert_response :success
  end
end
