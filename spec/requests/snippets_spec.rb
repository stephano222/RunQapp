require "rails_helper"

RSpec.describe "コード" do
  let(:taro) { create(:user, password: "password1234") }
  let(:hanako) { create(:user, password: "password1234") }

  # 何度も書くログイン処理をまとめておく。
  # spec/support に置いて全体で共用してもよいが、
  # 使うのがこのファイルだけのうちは手元に置いておく。
  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "GET /snippets" do
    let!(:official) { create(:snippet, title: "公式のコード") }
    let!(:taro_snippet) { create(:snippet, title: "太郎のコード", user: taro) }
    let!(:hanako_snippet) { create(:snippet, title: "花子のコード", user: hanako) }

    before { login_as(taro) }

    it "公式のコードを載せる" do
      get snippets_path

      expect(response.body).to include("公式のコード")
    end

    it "自分で追加したコードを載せる" do
      get snippets_path

      expect(response.body).to include("太郎のコード")
    end

    it "他の人が追加したコードは載せない" do
      get snippets_path

      expect(response.body).not_to include("花子のコード")
    end
  end

  describe "GET /snippets/:id" do
    before { login_as(taro) }

    it "自分のコードは開ける" do
      snippet = create(:snippet, user: taro)

      get snippet_path(snippet)

      expect(response).to have_http_status(:ok)
    end

    # URLを直接叩かれても中身を見せないことを確かめる。
    # 一覧に出さないだけでは、番号を変えて開かれてしまう。
    it "他の人のコードは開けない" do
      snippet = create(:snippet, title: "花子のコード", user: hanako)

      get snippet_path(snippet)

      expect(response).to redirect_to(snippets_path)
    end

    it "他の人のコードは練習画面も開けない" do
      snippet = create(:snippet, user: hanako)

      get practice_snippet_path(snippet, level: "easy")

      expect(response).to redirect_to(snippets_path)
    end
  end

  describe "GET /snippets/:id/practice" do
    let(:snippet) { create(:snippet) }

    before { login_as(taro) }

    it "指定された難易度で開く" do
      get practice_snippet_path(snippet, level: "hard")

      expect(response.body).to include("難しい(ノーヒント)")
    end

    # 知らない値が来ても画面が壊れないようにしておく。
    it "おかしな難易度が来たら優しいレベルにする" do
      get practice_snippet_path(snippet, level: "でたらめ")

      expect(response.body).to include("優しい(なぞる)")
    end
  end

  describe "コードの追加" do
    before { login_as(taro) }

    it "追加した人として自分が記録される" do
      category = create(:category)

      post snippets_path, params: {
        snippet: { title: "自作のコード", code: "puts 1", category_id: category.id }
      }

      expect(Snippet.last.user).to eq(taro)
    end

    it "題名がなければ追加しない" do
      category = create(:category)

      expect {
        post snippets_path, params: { snippet: { title: "", code: "puts 1", category_id: category.id } }
      }.not_to change(Snippet, :count)
    end
  end
end
