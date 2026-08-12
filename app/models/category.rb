class Category < ApplicationRecord
  has_many :quote_categories, dependent: :destroy
  has_many :quotes, through: :quote_categories

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
end
