require "rails_helper"

# 次回のログインでメールアドレスを表示する仕組み。
#
# 便利さと引き換えに、共用の端末で次の人にアドレスが見えうる。
# 保存する条件と、消える条件を一つずつ確かめる。
RSpec.describe "メールアドレスの記憶" do
  let!(:user) { create(:user, email: "taro@example.com", password: "runq-mori-taiken") }

  def login(email: "taro@example.com", password: "runq-mori-taiken", remember: nil)
    params = { email: email, password: password }
    params[:remember_email] = remember unless remember.nil?
    post login_path, params: params
  end

  describe "保存するとき" do
    it "チェックを入れてログインすると次回に表示する" do
      login(remember: "1")

      get login_path
      expect(response.body).to include("taro@example.com")
    end

    it "チェックの入った状態で開く" do
      login(remember: "1")

      get login_path
      expect(response.body).to include("checked")
    end

    # 大文字で入力されても、保存するのは登録されている形に揃える
    it "登録されている表記で保存する" do
      login(email: "TARO@Example.com", remember: "1")

      get login_path
      expect(response.body).to include("taro@example.com")
    end
  end

  describe "保存しないとき" do
    it "チェックを入れなければ表示しない" do
      login

      get login_path
      expect(response.body).not_to include("taro@example.com")
    end

    # パスワードを保存しないのは例外なし。
    # クッキーは中身を取り出せるので、盗まれた時点で入られてしまう。
    it "パスワードは保存しない" do
      login(remember: "1")

      expect(cookies.to_hash.values.join).not_to include("runq-mori-taiken")
    end

    it "ログインに失敗したときは保存しない" do
      login(password: "wrong", remember: "1")

      get login_path
      expect(response.body).not_to include('value="taro@example.com"')
    end
  end

  describe "消すとき" do
    it "チェックを外してログインし直すと消える" do
      login(remember: "1")
      login(remember: nil)

      get login_path
      expect(response.body).not_to include("taro@example.com")
    end

    # 記憶するのはアドレスだけで、ログインした状態ではない。
    it "ログアウトしてもアドレスの表示は残る" do
      login(remember: "1")
      delete logout_path

      get login_path
      expect(response.body).to include("taro@example.com")
    end
  end

  describe "直近の1件だけ持つ" do
    # 複数のアドレスを並べると、家族や同僚のものまで見えてしまう。
    it "別のアカウントで入ると上書きする" do
      create(:user, email: "hanako@example.com", password: "runq-mori-taiken")

      login(remember: "1")
      login(email: "hanako@example.com", remember: "1")

      get login_path
      expect(response.body).to include("hanako@example.com")
      expect(response.body).not_to include("taro@example.com")
    end
  end

  describe "入力し直すとき" do
    it "失敗しても打った内容は残す" do
      post login_path, params: { email: "taro@example.com", password: "wrong" }

      expect(response.body).to include("taro@example.com")
    end
  end

  describe "書き換えへの備え" do
    # 署名付きで持つので、中身を差し替えられても読まずに捨てる。
    it "細工されたクッキーは無視する" do
      cookies[SessionsController::REMEMBERED_EMAIL_COOKIE] = "attacker@example.com"

      get login_path

      expect(response.body).not_to include("attacker@example.com")
    end
  end
end
