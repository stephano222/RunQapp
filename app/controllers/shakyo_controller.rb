# 写経モード。
# 貼り付けたコードをその場で写すだけの機能なので、DBには保存しない。
# 採点や履歴も付けず、ひたすら写すことに集中できるようにしている。
class ShakyoController < ApplicationController
  before_action :require_login

  MAX_LENGTH = 20_000

  def new
  end

  def show
    @code = params[:code].to_s.delete("\r")

    if @code.strip.empty?
      flash.now[:alert] = "写経したいコードを貼り付けてください"
      return render :new, status: :unprocessable_entity
    end

    if @code.length > MAX_LENGTH
      flash.now[:alert] = "コードが長すぎます(#{MAX_LENGTH}文字まで)"
      return render :new, status: :unprocessable_entity
    end

    @title = params[:title].presence || "名称未設定の写経"
  end
end
