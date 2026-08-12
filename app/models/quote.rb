class Quote < ApplicationRecord
  belongs_to :author
  has_many :quote_categories, dependent: :destroy
  has_many :categories, through: :quote_categories

  validates :body, presence: true
end
