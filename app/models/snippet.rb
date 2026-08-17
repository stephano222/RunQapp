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

  # 和訳の3種類はいずれも「見出し:内容」を改行で並べた素直な形式で持つ。
  # 専用テーブルを作るほどの構造ではないため、テキスト1列で扱う。

  # 1行ごとの読み下し → [["resources :posts", "postsの7つのルートを作る"], ...]
  def line_notes_pairs
    parse_pairs(line_notes)
  end

  # 英単語の意味 → [["resources", "資源。一連の操作をまとめたもの"], ...]
  def glossary_pairs
    parse_pairs(glossary)
  end

  def translated?
    summary.present? || line_notes.present? || glossary.present?
  end

  private

  # 区切りは前後に空白のある「 : 」。
  # コード側にも :posts や null: のような「:」が出るため、
  # 単純な「:」では誤って切れてしまう。さらに最後の区切りで分けることで、
  # コード中に「 : 」が現れても意味の側を正しく取り出せる。
  SEPARATOR = " : ".freeze

  def parse_pairs(text)
    return [] if text.blank?

    text.split("\n").filter_map do |line|
      next if line.strip.empty?

      key, separator, value = line.rpartition(SEPARATOR)
      next if separator.empty? || value.blank?

      [key.strip, value.strip]
    end
  end
end
