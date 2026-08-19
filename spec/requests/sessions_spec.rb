require "rails_helper"

# ここまでのモデルの検証と違い、実際にURLを叩いて確かめる。
# ログインできなくなると誰もアプリを使えないので、経路ごと固めておく。
RSpec.describe "ログイン" do
  describe "POST /login" do
    let!(:user) { create(:user, email: "taro@example.com", password: "password1234") }

    context "正しいアドレスとパスワードのとき" do
      it "トップページへ送る" do
        post login_path, params: { email: "taro@example.com", password: "password1234" }

        expect(response).to redirect_to(root_path)
      end

      it "ログインした状態になる" do
        post login_path, params: { email: "taro@example.com", password: "password1234" }
        follow_redirect!

        expect(response.body).to include(user.name)
      end

      it "大文字で入力されても受け付ける" do
        post login_path, params: { email: "Taro@Example.com", password: "password1234" }

        expect(response).to redirect_to(root_path)
      end

      it "ログインした回数を記録する" do
        expect {
          post login_path, params: { email: "taro@example.com", password: "password1234" }
        }.to change { user.reload.sign_in_count }.by(1)
      end
    end

    context "パスワードが違うとき" do
      it "ログインさせない" do
        post login_path, params: { email: "taro@example.com", password: "wrong" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("メールアドレスかパスワードが正しくありません")
      end
    end

    context "登録のないアドレスのとき" do
      # アドレスの有無で応答を変えると、登録済みかどうかを外から探れてしまう。
      # パスワード違いと同じ文言に揃えておく。
      it "パスワード違いと同じ扱いにする" do
        post login_path, params: { email: "unknown@example.com", password: "password1234" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("メールアドレスかパスワードが正しくありません")
      end
    end
  end

  describe "POST /guest_login" do
    context "ゲスト用のアカウントがあるとき" do
      let!(:guest) { create(:user, email: User::GUEST_EMAIL, name: User::GUEST_NAME) }

      it "何も入力せずにログインできる" do
        post guest_login_path

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include(User::GUEST_NAME)
      end

      # 誰でも入れるアカウントなので、利用状況が見えてしまうと困る。
      it "管理者権限は付かない" do
        ENV["ADMIN_EMAIL"] = "someone@example.com"

        post guest_login_path

        expect(guest.reload.admin?).to be false
      ensure
        ENV.delete("ADMIN_EMAIL")
      end
    end

    context "ゲスト用のアカウントが無いとき" do
      it "ログイン画面へ戻して知らせる" do
        post guest_login_path

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "ログインしていないとき" do
    it "コード一覧はログイン画面へ送る" do
      get snippets_path

      expect(response).to redirect_to(login_path)
    end

    it "管理画面もログイン画面へ送る" do
      get admin_dashboard_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "管理画面の入り口" do
    it "管理者でない人は入れない" do
      post login_path, params: { email: create(:user, password: "password1234").email, password: "password1234" }

      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "管理者なら開ける" do
      admin = create(:user, :admin, password: "password1234")
      post login_path, params: { email: admin.email, password: "password1234" }

      get admin_dashboard_path

      expect(response).to have_http_status(:ok)
    end
  end
end
