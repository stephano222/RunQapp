class UsersController < ApplicationController
  before_action :require_login, only: [:edit, :update]

  def new
    redirect_to root_path and return if logged_in?

    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "登録しました。さっそく練習を始めましょう!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = current_user
  end

  def update
    if current_user.update(update_user_params)
      redirect_to edit_user_path, notice: "プロフィールを更新しました"
    else
      @user = current_user
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def update_user_params
    permitted = params.require(:user).permit(:name, :email, :password)
    permitted.delete(:password) if permitted[:password].blank?
    permitted
  end
end
