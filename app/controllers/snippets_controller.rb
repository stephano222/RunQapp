class SnippetsController < ApplicationController
  before_action :require_login
  before_action :set_snippet, only: [:show, :edit, :update, :destroy, :practice, :memo]
  before_action :require_owner, only: [:edit, :update, :destroy, :memo]

  LEVELS = %w[easy normal hard].freeze

  def index
    @categories = Category.all
    # カテゴリごとに分けて渡す。ビューから category.snippets を辿ると
    # 他の人が追加したコードまで含まれてしまうため。
    @snippets_by_category = Snippet.visible_to(current_user).order(:id).group_by(&:category_id)
    # 一覧の各行に自己ベストを出すため、まとめて1回で引く
    @best_accuracy_by_snippet = current_user.attempts.group(:snippet_id).maximum(:accuracy)
    @snippet = Snippet.new
  end

  def show
    @attempts = current_user.attempts.where(snippet: @snippet).order(created_at: :desc).limit(10)
  end

  def new
    @snippet = Snippet.new
  end

  def create
    @snippet = current_user.snippets.new(snippet_params)

    if @snippet.save
      redirect_to @snippet, notice: "コードを追加しました"
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @snippet.update(snippet_params)
      redirect_to @snippet, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @snippet.destroy
    redirect_to snippets_path, notice: "削除しました"
  end

  def practice
    @level = LEVELS.include?(params[:level]) ? params[:level] : "easy"
  end

  # 練習画面から、メモだけを更新する
  def memo
    if @snippet.update(memo: params[:memo])
      render json: { ok: true }
    else
      render json: { ok: false }, status: :unprocessable_entity
    end
  end

  private

  # 他の人が追加したコードは、URLを直接叩かれても開かせない。
  def set_snippet
    @snippet = Snippet.visible_to(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to snippets_path, alert: "そのコードは見つかりません"
  end

  def require_owner
    return if @snippet.editable_by?(current_user)

    redirect_to snippets_path, alert: "このコードは編集できません"
  end

  def snippet_params
    params.require(:snippet).permit(:category_id, :title, :code, :explanation, :language, :memo)
  end
end
