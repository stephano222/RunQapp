class Snippet < ApplicationRecord
  belongs_to :category
  belongs_to :user, optional: true
  has_many :attempts, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :code, presence: true

  scope :official, -> { where(user_id: nil) }
  scope :custom, -> { where.not(user_id: nil) }

  def official?
    user_id.nil?
  end

  def editable_by?(current_user)
    current_user.present? && user_id == current_user.id
  end
end
