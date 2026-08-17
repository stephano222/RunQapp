class User < ApplicationRecord
  has_secure_password

  # 誰でも試せるお試し用アカウント。ログイン画面に入力済みで表示する。
  # 隠す前提のものではないので、ここに書いてシードと画面で共用する。
  #
  # パスワードは流出一覧に載っていない文字列にしておく。
  # test1234 のようなありふれたものだと、ブラウザが流出を検知して
  # ログインのたびに「パスワードを変更してください」と警告を出す。
  DEMO_EMAIL = "test@example.com".freeze
  DEMO_PASSWORD = "runq-mori-taiken".freeze

  has_many :snippets, dependent: :nullify
  has_many :attempts, dependent: :destroy

  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 30 }
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # 管理者にするアドレス。環境変数 ADMIN_EMAIL で指定する。
  # 管理画面などに貼り付けると前後に空白や改行が紛れ込みやすく、
  # そのままだと一致せずに静かに失敗するので必ず整形してから使う。
  def self.admin_email
    ENV["ADMIN_EMAIL"].to_s.strip.downcase.presence
  end

  # 指定のアドレスなら管理者権限を与える。
  # シードは配置のたびにしか動かないため、それ以降に登録した人が
  # いつまでも権限を得られない。ログインのたびに確かめて追いつかせる。
  def sync_admin_flag!
    target = self.class.admin_email
    # 未設定のときは何もしない。設定を消しただけで既存の権限まで
    # 失われると、管理画面に入れなくなって復旧できなくなる。
    return if target.nil?

    should_be_admin = email == target
    update_columns(admin: should_be_admin) if admin? != should_be_admin
  end

  # ログインのたびに回数と日時を記録する。
  # 検証を挟まずに更新するので、パスワード変更中などでも確実に残る。
  def record_sign_in!
    update_columns(
      sign_in_count: sign_in_count + 1,
      last_sign_in_at: Time.current
    )
  end
end
