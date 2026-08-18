require "rails_helper"

RSpec.describe "和訳" do
  let(:user) { create(:user, password: "password1234") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "GET /translate" do
    it "ログインしていなければ入れない" do
      get translate_path

      expect(response).to redirect_to(login_path)
    end

    it "ログインしていれば貼り付け画面を出す" do
      login_as(user)

      get translate_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /translate" do
    before { login_as(user) }

    it "全体の意味・1行ごとの意味・単語の意味を出す" do
      post translate_path, params: { code: "resources :posts" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("resources")
    end

    it "複数行でもそれぞれ訳す" do
      post translate_path, params: { code: "resources :posts\nvalidates :title, presence: true" }

      expect(response.body).to include("validates")
    end

    it "訳せない行があっても画面は出す" do
      post translate_path, params: { code: "???????" }

      expect(response).to have_http_status(:ok)
    end

    context "コードが渡されなかったとき" do
      it "貼り付けるよう促す" do
        post translate_path, params: { code: "" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("貼り付けてください")
      end
    end

    context "コードが長すぎるとき" do
      it "上限を超えたら断る" do
        post translate_path, params: { code: "a" * (TranslationsController::MAX_LENGTH + 1) }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("長すぎます")
      end
    end

    it "貼り付けた内容を保存しない" do
      expect {
        post translate_path, params: { code: "resources :posts" }
      }.not_to change(Snippet, :count)
    end
  end
end
