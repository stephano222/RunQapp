class AttemptsController < ApplicationController
  before_action :require_login

  def index
    @attempts_by_snippet = current_user.attempts
                                        .includes(snippet: :category)
                                        .order(created_at: :desc)
                                        .group_by(&:snippet)

    @review_snippets = @attempts_by_snippet.select do |_, attempts|
      attempts.first.needs_review?
    end.keys
  end

  def show
    @attempt = current_user.attempts.find(params[:id])
    @snippet = @attempt.snippet
    @diff = build_diff(@attempt.input_text, @snippet.code)
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

  def build_diff(input, target)
    length = [input.length, target.length].max
    (0...length).map do |i|
      { expected: target[i], typed: input[i], match: input[i] == target[i] }
    end
  end
end
