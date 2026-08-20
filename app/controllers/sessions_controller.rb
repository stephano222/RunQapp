class SessionsController < ApplicationController
  # 次回のログインで表示するメールアドレスの保存先。
  #
  # パスワードは絶対に入れない。クッキーは中身を取り出せるので、
  # 盗まれた時点でログインされてしまう。
  #
  # 保存するのは直近の1件だけにする。過去に使った複数のアドレスを
  # 並べると、家族や同僚のアドレスまで見えてしまう。
  REMEMBERED_EMAIL_COOKIE = :remembered_email
  REMEMBER_DURATION = 30.days

  def new
    # チェックを入れた人だけ、前回のアドレスが入った状態で開く
    @email = remembered_email
    @remember = @email.present?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      user.sync_admin_flag!
      user.record_sign_in!
      update_remembered_email(user.email)
      redirect_to root_path, notice: "ログインしました"
    else
      # 打ち直しの手間を省くため、入れた値と選択は残したまま出し直す
      @email = params[:email]
      @remember = remember_requested?
      flash.now[:alert] = "メールアドレスかパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  # ゲスト用のアカウントに、メールアドレスもパスワードも打たずに入る。
  # 中身はログインと同じで、入力の手間を省くだけ。
  def guest
    user = User.find_by(email: User::GUEST_EMAIL)

    if user
      session[:user_id] = user.id
      user.sync_admin_flag!
      user.record_sign_in!
      redirect_to root_path, notice: "ゲストとしてログインしました"
    else
      # シードが流れていない環境では用意されていないことがある
      redirect_to login_path, alert: "ゲスト用のアカウントが見つかりませんでした"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "ログアウトしました"
  end

  private

  # 署名付きで読み書きする。手元で書き換えられても、
  # 印が合わなければ読まずに捨てる。
  def remembered_email
    cookies.signed[REMEMBERED_EMAIL_COOKIE].presence
  end

  def update_remembered_email(email)
    if remember_requested?
      cookies.signed[REMEMBERED_EMAIL_COOKIE] = {
        value: email,
        expires: REMEMBER_DURATION.from_now,
        # 画面に出す以外の用途がないので、通信の盗み見だけ防いでおく
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    else
      # 外したときは残さない。共用の端末で次の人に見えてしまう
      cookies.delete(REMEMBERED_EMAIL_COOKIE)
    end
  end

  def remember_requested?
    ActiveModel::Type::Boolean.new.cast(params[:remember_email])
  end
end
