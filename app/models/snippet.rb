class Snippet < ApplicationRecord
  belongs_to :category
  belongs_to :user, optional: true
  has_many :attempts, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :code, presence: true

  scope :official, -> { where(user_id: nil) }
  scope :custom, -> { where.not(user_id: nil) }

  # 見せてよい範囲。最初から入っている公式のコードは全員に見せるが、
  # 各自が追加したコードは本人にだけ見せる。
  # 一覧・カテゴリ・練習画面のいずれもこの範囲を通す。
  scope :visible_to, ->(user) { where(user_id: [nil, user&.id]) }

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

  # 一覧画面と同じ並び(カテゴリの順 → コードのid順)で、次に練習するコードを返す。
  # 同じカテゴリを打ち終えたら次のカテゴリの先頭へ進む。
  # 最後のコードまで来たら nil を返し、呼び出し側で終わりを知らせる。
  #
  # 一覧に出ないコードへ飛ばしてしまわないよう、見える範囲だけをたどる。
  def next_in_course(user)
    scope = Snippet.visible_to(user)

    scope.where(category_id: category_id).where("snippets.id > ?", id).order(:id).first ||
      first_of_following_category(scope)
  end

  private

  # カテゴリ自体の並びは position、同じ position なら id で決まる。
  # 一覧の表示順と食い違わないよう、ここでも同じ条件で次を探す。
  def first_of_following_category(scope)
    scope
      .joins(:category)
      .where(
        "categories.position > :position OR (categories.position = :position AND categories.id > :id)",
        position: category.position, id: category.id
      )
      .order("categories.position ASC", "categories.id ASC", "snippets.id ASC")
      .first
  end

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
