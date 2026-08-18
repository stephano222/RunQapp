require "rails_helper"

RSpec.describe "カテゴリ" do
  let(:taro) { create(:user, password: "password1234") }
  let(:hanako) { create(:user, password: "password1234") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "GET /categories" do
    it "ログインしていなければ入れない" do
      get categories_path

      expect(response).to redirect_to(login_path)
    end

    context "ログインしているとき" do
      before { login_as(taro) }

      it "カテゴリを並べる" do
        create(:category, name: "ルーティング")

        get categories_path

        expect(response.body).to include("ルーティング")
      end

      # 表示件数と中身が食い違うと、開いてみて数が合わずに戸惑う。
      it "自分に見えるコードだけを数える" do
        category = create(:category)
        create(:snippet, category: category)
        create(:snippet, category: category, user: taro)
        create(:snippet, category: category, user: hanako)

        get categories_path

        expect(response.body).to include("2個のコード")
      end
    end
  end

  describe "GET /categories/:id" do
    let(:category) { create(:category, name: "ルーティング") }

    before { login_as(taro) }

    it "そのカテゴリのコードを並べる" do
      create(:snippet, title: "公式のコード", category: category)

      get category_path(category)

      expect(response.body).to include("公式のコード")
    end

    it "他の人が追加したコードは並べない" do
      create(:snippet, title: "花子のコード", category: category, user: hanako)

      get category_path(category)

      expect(response.body).not_to include("花子のコード")
    end

    it "各行からレベルを選んで練習に入れる" do
      snippet = create(:snippet, category: category)

      get category_path(category)

      expect(response.body).to include(practice_snippet_path(snippet, level: "easy"))
      expect(response.body).to include(practice_snippet_path(snippet, level: "hard"))
    end

    it "まだ挑戦していなければ未挑戦と示す" do
      create(:snippet, category: category)

      get category_path(category)

      expect(response.body).to include("未挑戦")
    end

    it "挑戦済みなら自己ベストを示す" do
      snippet = create(:snippet, category: category)
      create(:attempt, user: taro, snippet: snippet, accuracy: 95)

      get category_path(category)

      expect(response.body).to include("自己ベスト")
    end

    # 他人の成績が自分の自己ベストとして出ては困る。
    it "自己ベストは自分の記録から出す" do
      snippet = create(:snippet, category: category)
      create(:attempt, user: hanako, snippet: snippet, accuracy: 100)

      get category_path(category)

      expect(response.body).to include("未挑戦")
    end
  end
end
