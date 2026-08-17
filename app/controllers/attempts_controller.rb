class AttemptsController < ApplicationController
  before_action :require_login

  # 復習画面の1行分。コードと、その最新の挑戦、そして通算の集計を持つ。
  Summary = Struct.new(:snippet, :latest, :try_count, :best_accuracy, keyword_init: true) do
    def needs_review?
      latest.needs_review?
    end
  end

  def index
    @summaries = build_summaries
    @review_summaries = @summaries.select(&:needs_review?)
  end

  def show
    @attempt = current_user.attempts.find(params[:id])
    @snippet = @attempt.snippet
    @diff = build_diff(@attempt.input_text, @snippet.code)
    # 採点結果から、一覧に戻らずに前後の課題へ移れるようにする
    @prev_snippet = @snippet.prev_in_course(current_user)
    @next_snippet = @snippet.next_in_course(current_user)
  end

  def create
    @attempt = current_user.attempts.new(attempt_params)

    if @attempt.save
      render json: { redirect_url: attempt_path(@attempt) }, status: :created
    else
      render json: { errors: @attempt.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def attempt_params
    params.require(:attempt).permit(:snippet_id, :level, :input_text, :accuracy, :mistake_count, :duration_ms, :correct)
  end

  # 画面に出すのはコードごとに1行だけなので、その1行分に必要なものだけを集める。
  #
  # 以前は全ての練習記録を読み込んでからRubyで束ねていた。
  # それだと練習を重ねるほど読み込む量が比例して増え、
  # 3万件で250ms前後かかっていた。同じ結果をデータベース側で
  # 絞れば読み込むのはコードの数だけで済み、15ms前後に収まる。
  def build_summaries
    latest_attempts = latest_attempt_per_snippet
    return [] if latest_attempts.empty?

    try_counts = current_user.attempts.group(:snippet_id).count
    best_accuracies = current_user.attempts.group(:snippet_id).maximum(:accuracy)

    latest_attempts.map { |attempt|
      Summary.new(
        snippet: attempt.snippet,
        latest: attempt,
        try_count: try_counts[attempt.snippet_id],
        best_accuracy: best_accuracies[attempt.snippet_id]
      )
    }.sort_by { |summary| -summary.latest.created_at.to_f }
  end

  # コードごとの最新1件だけを取り出す。
  # DISTINCT ON はPostgreSQLの書き方で、並び順の先頭1件を各グループから拾う。
  # 同じ時刻の記録が並んだときに順序が揺れないよう、idも並びに加えている。
  def latest_attempt_per_snippet
    newest_per_snippet = current_user.attempts
                                     .select("DISTINCT ON (snippet_id) *")
                                     .order("snippet_id, created_at DESC, id DESC")

    Attempt.from(newest_per_snippet, :attempts).includes(snippet: :category).to_a
  end

  def build_diff(input, target)
    length = [input.length, target.length].max
    (0...length).map do |i|
      { expected: target[i], typed: input[i], match: input[i] == target[i] }
    end
  end
end
