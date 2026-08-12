require "test_helper"

class CategoryTest < ActiveSupport::TestCase
test "is valid with a name and slug" do
  category = Category.new(name: "gratitude", slug: "gratitude")
  assert category.valid?
end

  test "is invalid without a name" do
    category = Category.new(slug: "inspirational")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "is invalid without a slug" do
    category = Category.new(name: "inspirational")
    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"
  end

  test "name must be unique" do
    duplicate = categories(:inspirational).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "slug must be unique" do
    duplicate = categories(:inspirational).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "has many quote_categories" do
    assert_kind_of QuoteCategory, categories(:inspirational).quote_categories.first
  end

  test "has many quotes through quote_categories" do
    category = categories(:inspirational)
    assert_equal 2, category.quotes.count
    assert_includes category.quotes, quotes(:braver)
    assert_includes category.quotes, quotes(:bestself)
  end
end
