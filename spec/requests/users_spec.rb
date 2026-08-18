require "rails_helper"

RSpec.describe "利用者" do
  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "新規登録" do
    let(:valid_params) do
      { user: { name: "新入り太郎", email: "newcomer@example.com", password: "password1234" } }
    end

    it "登録できる" do
      expect { post signup_path, params: valid_params }.to change(User, :count).by(1)
    end

    it "登録するとそのままログインした状態になる" do
      post signup_path, params: valid_params
      follow_redirect!

      expect(response.body).to include("新入り太郎")
    end

    it "管理者にはならない" do
      post signup_path, params: valid_params

      expect(User.last.admin?).to be false
    end

    context "入力が足りないとき" do
      it "名前がなければ登録しない" do
        expect {
          post signup_path, params: { user: { name: "", email: "a@example.com", password: "password1234" } }
        }.not_to change(User, :count)
      end

      it "パスワードが短ければ登録しない" do
        expect {
          post signup_path, params: { user: { name: "太郎", email: "a@example.com", password: "12345" } }
        }.not_to change(User, :count)
      end

      it "メールアドレスの形が違えば登録しない" do
        expect {
          post signup_path, params: { user: { name: "太郎", email: "アドレスではない", password: "password1234" } }
        }.not_to change(User, :count)
      end

      it "既に使われているアドレスでは登録しない" do
        create(:user, email: "taken@example.com")

        expect {
          post signup_path, params: { user: { name: "太郎", email: "taken@example.com", password: "password1234" } }
        }.not_to change(User, :count)
      end
    end

    it "ログイン済みなら登録画面を出さない" do
      login_as(create(:user, password: "password1234"))

      get signup_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "プロフィールの変更" do
    let(:user) { create(:user, name: "変更前", password: "password1234") }

    before { login_as(user) }

    it "ログインしていなければ入れない" do
      delete logout_path

      get edit_user_path

      expect(response).to redirect_to(login_path)
    end

    it "名前を変えられる" do
      patch user_path, params: { user: { name: "変更後" } }

      expect(user.reload.name).to eq("変更後")
    end

    # パスワード欄を空のまま名前だけ直す場面が多い。
    # 空を「空のパスワードに変更」と受け取ると、ログインできなくなる。
    it "パスワード欄が空なら今のパスワードのままにする" do
      patch user_path, params: { user: { name: "変更後", password: "" } }

      expect(user.reload.authenticate("password1234")).to be_truthy
    end

    it "パスワードを入れればそれに変わる" do
      patch user_path, params: { user: { password: "newpassword1234" } }

      expect(user.reload.authenticate("newpassword1234")).to be_truthy
    end

    it "自分を管理者にはできない" do
      patch user_path, params: { user: { name: "変更後", admin: true } }

      expect(user.reload.admin?).to be false
    end
  end

  describe "ログアウト" do
    it "ログインしていない状態に戻す" do
      user = create(:user, password: "password1234")
      login_as(user)

      delete logout_path

      get snippets_path
      expect(response).to redirect_to(login_path)
    end
  end
end
