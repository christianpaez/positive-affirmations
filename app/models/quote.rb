class Quote < ApplicationRecord
  belongs_to :author
  has_many :quote_categories, dependent: :destroy
  has_many :categories, through: :quote_categories

  validates :body, presence: true

def self.random
  find_by_sql([
    "SELECT quotes.id, quotes.body, quotes.author_id, quotes.created_at, quotes.updated_at,
            authors.name, authors.slug
     FROM quotes
     LEFT JOIN authors ON quotes.author_id = authors.id
     LEFT JOIN quote_categories ON quote_categories.quote_id = quotes.id
     ORDER BY RANDOM()
     LIMIT 1"
  ]).first
end
end
