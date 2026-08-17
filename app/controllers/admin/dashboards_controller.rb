module Admin
  # 管理者だけが見られる利用状況の画面。
  # 個人が何を打ったかまでは扱わず、件数や平均といった集計に留めている。
  class DashboardsController < ApplicationController
    before_action :require_login
    before_action :require_admin

    def show
      @user_count = User.count
      @new_users_this_week = User.where(created_at: 1.week.ago..).count
      @signed_in_users = User.where("sign_in_count > 0").count
      @total_sign_ins = User.sum(:sign_in_count)

      @attempt_count = Attempt.count
      @attempts_this_week = Attempt.where(created_at: 1.week.ago..).count
      @average_accuracy = Attempt.average(:accuracy)&.round(1)

      @snippet_count = Snippet.count
      @custom_snippet_count = Snippet.custom.count

      # よく練習されているコード
      @popular_snippets = Snippet
        .joins(:attempts)
        .group("snippets.id", "snippets.title")
        .order(Arel.sql("COUNT(attempts.id) DESC"))
        .limit(10)
        .count("attempts.id")

      # 平均正答率が低い=つまずかれやすいコード(3回以上挑戦されたものに限る)
      @difficult_snippets = Snippet
        .joins(:attempts)
        .group("snippets.id", "snippets.title")
        .having("COUNT(attempts.id) >= 3")
        .order(Arel.sql("AVG(attempts.accuracy) ASC"))
        .limit(10)
        .average("attempts.accuracy")

      # レベルごとの利用状況
      @attempts_by_level = Attempt.group(:level).count

      # 利用者ごとの状況。名前とメールは伏せ、識別子と回数だけを見る。
      @recent_users = User.order(last_sign_in_at: :desc).limit(20)
    end

    private

    def require_admin
      return if current_user&.admin?

      redirect_to root_path, alert: "この画面は管理者のみ利用できます"
    end
  end
end
