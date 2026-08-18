require "rails_helper"

RSpec.describe "トップページ" do
  let(:user) { create(:user, name: "太郎", password: "password1234") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "ログインしていないとき" do
    it "案内の画面を出す" do
      get root_path

      expect(response.body).to include("重要なRailsコードを、打って覚える。")
    end

    it "ゲストで入る導線を置く" do
      get root_path

      expect(response.body).to include(guest_login_path)
    end
  end

  describe "ログインしているとき" do
    before { login_as(user) }

    it "名前を添えて迎える" do
      get root_path

      expect(response.body).to include("ようこそ、太郎さん")
    end

    context "続けた記録" do
      it "まだ練習していなければ始めるよう促す" do
        get root_path

        expect(response.body).to include("今日から始めましょう")
      end

      it "今日やっていれば達成と伝える" do
        create(:attempt, user: user, created_at: Time.zone.now)

        get root_path

        expect(response.body).to include("今日も達成")
      end

      it "昨日までで今日がまだなら、そう伝える" do
        create(:attempt, user: user, created_at: 1.day.ago)

        get root_path

        expect(response.body).to include("今日はまだです")
      end

      it "今週の問題数を出す" do
        2.times { create(:attempt, user: user, created_at: Time.zone.now) }

        get root_path

        expect(response.body).to include("今週の問題")
      end

      it "今週の7日ぶんの印を並べる" do
        get root_path

        expect(response.body.scan("week-day-dot").size).to eq(7)
      end

      # 練習した日だけが塗られる。全部塗られていては意味がない。
      it "練習した日だけを塗る" do
        create(:attempt, user: user, created_at: Time.zone.now)

        get root_path

        expect(response.body.scan("is-done").size).to eq(1)
      end
    end

    it "他の人の記録は数えない" do
      create(:attempt, user: create(:user), created_at: Time.zone.now)

      get root_path

      expect(response.body).to include("今日から始めましょう")
    end
  end
end
