class Category < ApplicationRecord
  has_many :snippets, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  default_scope { order(:position, :id) }
end
