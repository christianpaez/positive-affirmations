class QuoteCategory < ApplicationRecord
  belongs_to :quote
  belongs_to :category

  validates :quote_id, uniqueness: { scope: :category_id }
end
