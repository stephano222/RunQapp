class CategoriesController < ApplicationController
  before_action :require_login

  def index
    @categories = Category.all
    # 件数も見える範囲だけで数える。開いてみたら中身が少ない、
    # という食い違いが起きないようにする。
    @snippet_counts = Snippet.visible_to(current_user).group(:category_id).count
  end

  def show
    @category = Category.find(params[:id])
    @snippets = @category.snippets.visible_to(current_user).order(:id)
    @best_accuracy_by_snippet = current_user.attempts
                                             .where(snippet_id: @snippets.map(&:id))
                                             .group(:snippet_id)
                                             .maximum(:accuracy)
  end
end
