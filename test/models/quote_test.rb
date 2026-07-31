require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  test "is valid with a body and author" do
    quote = Quote.new(body: "Example body.", author: authors(:oscar))
    assert quote.valid?
  end

  test "is invalid without a body" do
    quote = Quote.new(author: authors(:oscar))
    assert_not quote.valid?
    assert_includes quote.errors[:body], "can't be blank"
  end

  test "is invalid without an author" do
    quote = Quote.new(body: "Example body.")
    assert_not quote.valid?
    assert_includes quote.errors[:author], "must exist"
  end

  test "belongs to an author" do
    assert_equal authors(:aamilne), quotes(:braver).author
  end

  test "has many quote_categories" do
    assert_kind_of QuoteCategory, quotes(:braver).quote_categories.first
  end

  test "has many categories through quote_categories" do
    quote = quotes(:braver)
    assert_equal 2, quote.categories.count
    assert_includes quote.categories, categories(:inspirational)
    assert_includes quote.categories, categories(:motivation)
  end
end
