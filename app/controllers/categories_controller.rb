class CategoriesController < ApplicationController
  before_action :require_login

  def index
    @categories = Category.includes(:snippets)
  end

  def show
    @category = Category.find(params[:id])
    @snippets = @category.snippets.order(:id)
    @best_accuracy_by_snippet = current_user.attempts
                                             .where(snippet_id: @snippets.map(&:id))
                                             .group(:snippet_id)
                                             .maximum(:accuracy)
  end
end
