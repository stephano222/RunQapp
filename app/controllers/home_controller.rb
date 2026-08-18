class HomeController < ApplicationController
  def index
    return unless logged_in?

    @categories = Category.all
    @snippet_counts = Snippet.visible_to(current_user).group(:category_id).count
    @recent_attempts = current_user.attempts.order(created_at: :desc).limit(5).includes(:snippet)

    # 続けられているかを見せる。回数だけでは、続いているのか
    # 久しぶりなのかが分からないため。
    @streak = current_user.practice_streak
    @attempts_this_week = current_user.attempts_this_week
    @practiced_days = current_user.practiced_days_this_week
    @this_week = Time.zone.today.beginning_of_week..Time.zone.today.end_of_week
    @review_count = current_user.attempts.where("accuracy < ?", Attempt::REVIEW_THRESHOLD).select(:snippet_id).distinct.count
  end
end
