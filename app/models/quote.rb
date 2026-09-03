class Quote < ApplicationRecord
  belongs_to :author
  has_many :quote_categories, dependent: :destroy
  has_many :categories, through: :quote_categories

  validates :body, presence: true

  def self.random
    Quote.find_by_sql("SELECT * FROM quotes ORDER BY RANDOM() LIMIT 1").first
  end
end
