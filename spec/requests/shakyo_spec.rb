require "rails_helper"

RSpec.describe "写経" do
  let(:user) { create(:user, password: "password1234") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "GET /shakyo" do
    it "ログインしていなければ入れない" do
      get shakyo_path

      expect(response).to redirect_to(login_path)
    end

    it "ログインしていれば貼り付け画面を出す" do
      login_as(user)

      get shakyo_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /shakyo" do
    before { login_as(user) }

    it "貼り付けたコードで写経の画面を出す" do
      post shakyo_path, params: { code: "resources :posts", title: "ルーティングの練習" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ルーティングの練習")
    end

    it "題名がなければ仮の名前を付ける" do
      post shakyo_path, params: { code: "resources :posts" }

      expect(response.body).to include("名称未設定の写経")
    end

    it "レベルを指定できる" do
      post shakyo_path, params: { code: "resources :posts", level: "hard" }

      expect(response).to have_http_status(:ok)
    end

    # 知らない値が来ても画面が壊れないようにしておく。
    it "おかしなレベルが来ても受け付ける" do
      post shakyo_path, params: { code: "resources :posts", level: "でたらめ" }

      expect(response).to have_http_status(:ok)
    end

    context "コードが渡されなかったとき" do
      it "貼り付けるよう促す" do
        post shakyo_path, params: { code: "" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("貼り付けてください")
      end

      it "空白だけでも促す" do
        post shakyo_path, params: { code: "   \n  " }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "コードが長すぎるとき" do
      # 上限がないと、極端に長いものを貼られたときに画面が固まる。
      it "上限を超えたら断る" do
        post shakyo_path, params: { code: "a" * (ShakyoController::MAX_LENGTH + 1) }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("長すぎます")
      end

      it "上限ちょうどなら受け付ける" do
        post shakyo_path, params: { code: "a" * ShakyoController::MAX_LENGTH }

        expect(response).to have_http_status(:ok)
      end
    end

    # 保存しないのがこの機能の方針。履歴も残さない。
    it "貼り付けた内容を保存しない" do
      expect {
        post shakyo_path, params: { code: "resources :posts" }
      }.not_to change(Snippet, :count)
    end
  end
end
