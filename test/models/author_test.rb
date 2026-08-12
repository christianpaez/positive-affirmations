require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "is valid with a name and slug" do
    author = Author.new(name: "Jane Austen", slug: "jane-austen")
    assert author.valid?
  end

  test "is invalid without a name" do
    author = Author.new(slug: "oscar-wilde")
    assert_not author.valid?
    assert_includes author.errors[:name], "can't be blank"
  end

  test "is invalid without a slug" do
    author = Author.new(name: "Oscar Wilde")
    assert_not author.valid?
    assert_includes author.errors[:slug], "can't be blank"
  end

  test "name must be unique" do
    duplicate = authors(:oscar).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "slug must be unique" do
    duplicate = authors(:oscar).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "has many quotes" do
    assert_equal 1, authors(:aamilne).quotes.count
    assert_kind_of Quote, authors(:aamilne).quotes.first
  end

  test "destroying an author destroys their quotes" do
    assert_difference "Quote.count", -1 do
      authors(:aamilne).destroy
    end
  end
end
