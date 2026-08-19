# ログインの試行回数を制限する。
#
# 制限がないと、パスワードを1秒に何十回でも試せてしまう。
# 利用者が短くありふれたパスワードを選んだ場合、総当たりで破られる。
#
# 数え方は2通り用意する。
#   1. 同じ所からの試行 … 1台から手当たり次第に試される場合
#   2. 同じ宛先への試行 … 大勢で1つのアカウントを狙われる場合
# 片方だけだと、もう片方のやり方をすり抜けられる。
class Rack::Attack
  # 数える場所。既定はRailsのキャッシュで、本番ではメモリ上に置かれる。
  # 台を増やすと台ごとに別々に数えることになるが、
  # 制限が緩くなるだけで、無いよりはるかによい。
  self.cache.store = ActiveSupport::Cache::MemoryStore.new

  # 試行の上限。人が手で打つ範囲では届かず、
  # 機械が総当たりするには厳しい、という間をとる。
  LOGIN_LIMIT_PER_IP = 10
  LOGIN_LIMIT_PER_EMAIL = 5
  LOGIN_PERIOD = 5.minutes

  # 1. 同じ所から繰り返しログインを試す場合
  throttle("logins/ip", limit: LOGIN_LIMIT_PER_IP, period: LOGIN_PERIOD) do |request|
    request.ip if request.post? && request.path == "/login"
  end

  # 2. 同じアドレス宛に繰り返しログインを試す場合
  throttle("logins/email", limit: LOGIN_LIMIT_PER_EMAIL, period: LOGIN_PERIOD) do |request|
    next unless request.post? && request.path == "/login"

    # 大文字小文字の違いで数え分けられないよう、揃えてから数える。
    email = request.params["email"].to_s.strip.downcase
    email.presence
  end

  # 3. 登録の繰り返し。自動で大量のアカウントを作られるのを防ぐ。
  throttle("signups/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.post? && request.path == "/signup"
  end

  # 制限に達したときの応答。
  # あと何秒待てばよいかを伝える。黙って断ると、
  # 利用者は不具合と区別がつかない。
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period].to_i

    [
      429,
      { "Content-Type" => "text/plain; charset=utf-8", "Retry-After" => retry_after.to_s },
      ["試行の回数が多すぎます。しばらく待ってからやり直してください。\n"]
    ]
  end

  # テストでは既定で止めておく。
  # 有効なままだと、続けてログインする他のテストが巻き添えで弾かれる。
  # 制限そのものを確かめるテストの中でだけ、明示的に有効にする。
  self.enabled = !Rails.env.test?
end
