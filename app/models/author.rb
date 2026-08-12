class Author < ApplicationRecord
  has_many :quotes, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
end
