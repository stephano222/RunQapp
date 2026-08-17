class User < ApplicationRecord
  has_secure_password

  has_many :snippets, dependent: :nullify
  has_many :attempts, dependent: :destroy

  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 30 }
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # ログインのたびに回数と日時を記録する。
  # 検証を挟まずに更新するので、パスワード変更中などでも確実に残る。
  def record_sign_in!
    update_columns(
      sign_in_count: sign_in_count + 1,
      last_sign_in_at: Time.current
    )
  end
end
