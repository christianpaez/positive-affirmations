require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  test "returns a random quote" do
    quote = quotes(:braver)
    Quote.define_singleton_method(:random) { quote }

    get quotes_random_url
    assert_response :success
    assert_includes response.body, quote.body
  ensure
    Quote.singleton_class.send(:remove_method, :random)
  end
end
