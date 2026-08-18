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

  # 今日から何日続けて練習しているか。
  #
  # 今日まだ手をつけていなくても、昨日やっていれば途切れた扱いにしない。
  # 日付が変わった瞬間に0へ戻ると、続ける気をくじいてしまうため。
  def practice_streak(today = Time.zone.today)
    days = practice_dates
    return 0 if days.empty?

    # 数え始める日。今日か昨日に練習していなければ、記録は途切れている。
    start = [today, today - 1].find { |d| days.first == d }
    return 0 if start.nil?

    expected = start
    days.take_while { |day| (day == expected).tap { expected -= 1 } }.size
  end

  # 今週やった問題数。週の区切りは月曜から。
  def attempts_this_week(today = Time.zone.today)
    attempts.where(created_at: today.beginning_of_week..).count
  end

  # 今週のうち練習した日。7つの丸を塗り分けるために使う。
  def practiced_days_this_week(today = Time.zone.today)
    range = today.beginning_of_week..today.end_of_week
    practice_dates.select { |day| range.cover?(day) }.to_set
  end

  # 練習した日を新しい順に並べる。同じ日に何度やっても1日と数える。
  #
  # 日付への変換はデータベース側で行う。全ての記録を読み込んでから
  # Rubyで丸めると、練習を重ねるほど比例して重くなるため。
  def practice_dates
    zone = self.class.connection.quote(Time.zone.tzinfo.name)

    @practice_dates ||= attempts
      .distinct
      .pluck(Arel.sql("(created_at AT TIME ZONE 'UTC' AT TIME ZONE #{zone})::date"))
      .sort
      .reverse
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
