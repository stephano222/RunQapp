class HomeController < ApplicationController
  def index
    return unless logged_in?

    @categories = Category.includes(:snippets)
    @recent_attempts = current_user.attempts.order(created_at: :desc).limit(5).includes(:snippet)
    @review_count = current_user.attempts.where("accuracy < ?", Attempt::REVIEW_THRESHOLD).select(:snippet_id).distinct.count
  end
end
