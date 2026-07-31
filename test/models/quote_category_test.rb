require "test_helper"

class QuoteCategoryTest < ActiveSupport::TestCase
  test "is valid with a quote and category" do
    quote_category = QuoteCategory.new(quote: quotes(:gettingahead), category: categories(:confidence))
    assert quote_category.valid?
  end

  test "belongs to a quote" do
    assert_equal quotes(:braver), quote_categories(:braver_inspirational).quote
  end

  test "belongs to a category" do
    assert_equal categories(:inspirational), quote_categories(:braver_inspirational).category
  end

  test "quote and category pair must be unique" do
    duplicate = quote_categories(:braver_inspirational).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:quote_id], "has already been taken"
  end
end
