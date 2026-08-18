require "rails_helper"

RSpec.describe "利用状況" do
  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "誰が見られるか" do
    it "ログインしていなければログイン画面へ送る" do
      get admin_dashboard_path

      expect(response).to redirect_to(login_path)
    end

    it "管理者でない人はトップへ送る" do
      login_as(create(:user, password: "password1234"))

      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    # 誰でも入れるお試し用アカウントに権限が付くと、利用状況が全員に見える。
    it "お試し用アカウントは見られない" do
      guest = create(:user, email: User::DEMO_EMAIL, password: "password1234")
      login_as(guest)

      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "管理者なら開ける" do
      login_as(create(:user, :admin, password: "password1234"))

      get admin_dashboard_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "集計の中身" do
    let(:admin) { create(:user, :admin, password: "password1234") }

    before { login_as(admin) }

    it "記録が一つも無くても落ちない" do
      get admin_dashboard_path

      expect(response).to have_http_status(:ok)
    end

    it "利用者の数を数える" do
      create_list(:user, 2)

      get admin_dashboard_path

      # 管理者自身を含めて3人
      expect(response.body).to include("3")
    end

    it "練習の記録を数える" do
      snippet = create(:snippet, title: "よく練習されるコード")
      create_list(:attempt, 3, snippet: snippet, user: admin)

      get admin_dashboard_path

      expect(response.body).to include("よく練習されるコード")
    end

    # 3回以上挑戦されたものだけを対象にしている。
    # 1回だけの記録で「つまずかれやすい」と判断すると、偶然に振り回される。
    it "挑戦の少ないコードはつまずき一覧に入れない" do
      rare = create(:snippet, title: "一度だけのコード")
      create(:attempt, :needs_review, snippet: rare, user: admin)

      get admin_dashboard_path

      expect(response.body.scan("一度だけのコード").size).to be <= 1
    end

    it "利用者全員の記録を集計する" do
      other = create(:user)
      snippet = create(:snippet, title: "他の人が練習したコード")
      create_list(:attempt, 3, snippet: snippet, user: other)

      get admin_dashboard_path

      expect(response.body).to include("他の人が練習したコード")
    end
  end
end
