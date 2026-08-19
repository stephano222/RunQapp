# 今日やるとよいコードを選ぶ。
#
# 65件から毎回自分で選ぶのは、続けるほど面倒になる。
# 「どれをやろうか」で迷う時間をなくし、開いてすぐ打ち始められるようにする。
#
# 選び方の考えは単純で、忘れかけた頃にもう一度出す。
# 一度できたものを毎日出しても身につかないし、
# 間を空けすぎると忘れてしまう。間隔を少しずつ広げていく。
class PracticeRecommender
  # 合格した回数ごとの、次に出すまでの日数。
  # できるほど間隔を広げ、その分を新しいコードに回す。
  INTERVALS = [1, 3, 7, 14, 30].freeze

  # 画面に出す理由。なぜ勧められたのか分からないまま
  # 出されると、選ばされている感じがして続かない。
  # days_late は並べ替えに使うだけで、画面には出さない。
  # 「3日遅れ」と数字で出しても、責められている感じがするだけで役に立たない。
  Recommendation = Struct.new(:snippet, :reason, :level, :last_accuracy, :days_late, keyword_init: true)

  def initialize(user, today: Time.zone.today)
    @user = user
    @today = today
  end

  # 今日やるとよいものを、優先度の高い順に返す。
  def due(limit: 5)
    (overdue + untouched).first(limit)
  end

  # 期限が来ているものが何件あるか。画面の見出しに使う。
  def overdue_count
    overdue.size
  end

  private

  attr_reader :user, :today

  # 期限を過ぎたもの。遅れの大きい順、同じなら正答率の低い順に出す。
  def overdue
    @overdue ||= latest_attempts.filter_map { |attempt|
      days_late = (today - last_practiced_on(attempt)).to_i - interval_for(attempt)
      next if days_late.negative?

      Recommendation.new(
        snippet: attempt.snippet,
        level: attempt.level,
        last_accuracy: attempt.accuracy,
        days_late: days_late,
        reason: reason_for(attempt)
      )
    }.sort_by { |r| [-r.days_late, r.last_accuracy] }
  end

  # まだ一度も打っていないもの。並びは一覧と揃える。
  def untouched
    @untouched ||= Snippet
      .visible_to(user)
      .where.not(id: user.attempts.select(:snippet_id))
      .joins(:category)
      .order("categories.position ASC", "categories.id ASC", "snippets.id ASC")
      .map { |snippet|
        Recommendation.new(snippet: snippet, level: "easy", reason: "はじめて", last_accuracy: nil)
      }
  end

  # コードごとの直近1件。全ての記録を読み込むと、
  # 練習を重ねるほど比例して重くなるため、データベース側で絞る。
  def latest_attempts
    @latest_attempts ||= begin
      newest = user.attempts
                   .select("DISTINCT ON (snippet_id) *")
                   .order("snippet_id, created_at DESC, id DESC")

      Attempt.from(newest, :attempts)
             .includes(snippet: :category)
             .to_a
             .select { |attempt| visible_snippet_ids.include?(attempt.snippet_id) }
    end
  end

  # 自分が追加して消したコードなど、もう見えないものは勧めない。
  def visible_snippet_ids
    @visible_snippet_ids ||= Snippet.visible_to(user).pluck(:id).to_set
  end

  # 合格した回数。多いほど身についているとみなし、間隔を広げる。
  def pass_counts
    @pass_counts ||= user.attempts
                         .where(accuracy: Attempt::REVIEW_THRESHOLD..)
                         .group(:snippet_id)
                         .count
  end

  def interval_for(attempt)
    # 直近で落としていれば、積み上げた間隔は一度戻す。
    # できなくなったものを30日後に回すと、そのまま忘れてしまう。
    return INTERVALS.first if attempt.needs_review?

    level = pass_counts.fetch(attempt.snippet_id, 0)
    INTERVALS[[level, INTERVALS.size - 1].min]
  end

  def last_practiced_on(attempt)
    attempt.created_at.in_time_zone.to_date
  end

  def reason_for(attempt)
    days_since = (today - last_practiced_on(attempt)).to_i

    if attempt.needs_review?
      "前回#{attempt.accuracy.round}%"
    elsif days_since >= 7
      "#{days_since}日ぶり"
    else
      "そろそろ復習"
    end
  end
end
