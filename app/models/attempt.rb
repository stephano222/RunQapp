class Attempt < ApplicationRecord
  REVIEW_THRESHOLD = 90.0

  belongs_to :user
  belongs_to :snippet

  enum level: { easy: 0, normal: 1, hard: 2 }

  validates :input_text, presence: true
  validates :accuracy, numericality: { in: 0..100 }
  validates :mistake_count, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_ms, numericality: { greater_than_or_equal_to: 0 }

  def needs_review?
    accuracy < REVIEW_THRESHOLD
  end

  def level_label
    { "easy" => "優しい", "normal" => "普通", "hard" => "難しい" }[level]
  end
end
