class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      user.sync_admin_flag!
      user.record_sign_in!
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスかパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  # お試し用アカウントに、メールアドレスもパスワードも打たずに入る。
  # 中身はログインと同じで、入力の手間を省くだけ。
  def guest
    user = User.find_by(email: User::DEMO_EMAIL)

    if user
      session[:user_id] = user.id
      user.sync_admin_flag!
      user.record_sign_in!
      redirect_to root_path, notice: "ゲストとしてログインしました"
    else
      # シードが流れていない環境では用意されていないことがある
      redirect_to login_path, alert: "お試し用アカウントが見つかりませんでした"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "ログアウトしました"
  end
end
