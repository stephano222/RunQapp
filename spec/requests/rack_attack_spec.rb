require "rails_helper"

# ログインの試行回数の制限。
#
# 制限は他のテストの邪魔になるため、既定では止めてある。
# ここでだけ有効にし、終わったら必ず元に戻す。
RSpec.describe "試行回数の制限" do
  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  let!(:user) { create(:user, email: "taro@example.com", password: "runq-mori-taiken") }

  def attempt_login(email: "taro@example.com", password: "wrong", ip: "1.2.3.4")
    post login_path, params: { email: email, password: password },
                     env: { "REMOTE_ADDR" => ip }
  end

  describe "同じアドレス宛の繰り返し" do
    it "上限までは受け付ける" do
      Rack::Attack::LOGIN_LIMIT_PER_EMAIL.times { attempt_login }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "上限を超えたら断る" do
      (Rack::Attack::LOGIN_LIMIT_PER_EMAIL + 1).times { attempt_login }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "待つべき時間を伝える" do
      (Rack::Attack::LOGIN_LIMIT_PER_EMAIL + 1).times { attempt_login }

      expect(response.headers["Retry-After"]).to be_present
      expect(response.body).to include("しばらく待ってから")
    end

    # 所を変えても、狙われているアカウントは守られる。
    # 大勢で1つのアカウントを狙う場合に効く。
    it "所を変えても同じアドレス宛なら数える" do
      (Rack::Attack::LOGIN_LIMIT_PER_EMAIL + 1).times.with_index do |_, i|
        attempt_login(ip: "10.0.0.#{i}")
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    # 大文字小文字で数え分けられると、簡単にすり抜けられる。
    it "大文字小文字を変えても同じものとして数える" do
      Rack::Attack::LOGIN_LIMIT_PER_EMAIL.times { attempt_login(email: "taro@example.com") }
      attempt_login(email: "TARO@EXAMPLE.COM")

      expect(response).to have_http_status(:too_many_requests)
    end

    it "別のアドレス宛なら巻き添えにしない" do
      (Rack::Attack::LOGIN_LIMIT_PER_EMAIL + 1).times { attempt_login(email: "taro@example.com") }

      create(:user, email: "hanako@example.com", password: "runq-mori-taiken")
      attempt_login(email: "hanako@example.com", password: "runq-mori-taiken")

      expect(response).to redirect_to(root_path)
    end
  end

  describe "同じ所からの繰り返し" do
    # 宛先を変えながら手当たり次第に試す場合に効く。
    it "宛先を変えても同じ所からなら数える" do
      (Rack::Attack::LOGIN_LIMIT_PER_IP + 1).times.with_index do |_, i|
        attempt_login(email: "user#{i}@example.com", ip: "9.9.9.9")
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it "別の所からなら巻き添えにしない" do
      (Rack::Attack::LOGIN_LIMIT_PER_IP + 1).times.with_index do |_, i|
        attempt_login(email: "user#{i}@example.com", ip: "9.9.9.9")
      end

      attempt_login(password: "runq-mori-taiken", ip: "5.5.5.5")

      expect(response).to redirect_to(root_path)
    end
  end

  describe "正しいパスワードのとき" do
    it "制限にかかっていなければ普通に入れる" do
      attempt_login(password: "runq-mori-taiken")

      expect(response).to redirect_to(root_path)
    end
  end

  describe "登録の繰り返し" do
    it "上限を超えたら断る" do
      6.times.with_index do |i|
        post signup_path,
             params: { user: { name: "太郎#{i}", email: "new#{i}@example.com", password: "runq-mori-taiken" } },
             env: { "REMOTE_ADDR" => "7.7.7.7" }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "制限の対象外" do
    it "画面を見るだけなら数えない" do
      20.times { get login_path, env: { "REMOTE_ADDR" => "8.8.8.8" } }

      expect(response).to have_http_status(:ok)
    end
  end
end
