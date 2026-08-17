# 和訳モード。
# 貼り付けたコードをその場で解析して日本語にするだけなので、保存はしない。
class TranslationsController < ApplicationController
  before_action :require_login

  MAX_LENGTH = 20_000

  def new
  end

  def show
    code = params[:code].to_s

    if code.strip.empty?
      flash.now[:alert] = "和訳したいコードを貼り付けてください"
      return render :new, status: :unprocessable_entity
    end

    if code.length > MAX_LENGTH
      flash.now[:alert] = "コードが長すぎます(#{MAX_LENGTH}文字まで)"
      return render :new, status: :unprocessable_entity
    end

    @code = code
    @translator = CodeTranslator.new(code)
  end
end
