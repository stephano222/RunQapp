require "rails_helper"

RSpec.describe "採点結果" do
  let(:user) { create(:user, password: "password1234") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password1234" }
  end

  describe "GET /attempts/:id" do
    let(:category) { create(:category, position: 1) }
    let!(:previous_snippet) { create(:snippet, title: "前のコード", category: category) }
    let!(:current_snippet) { create(:snippet, title: "今のコード", category: category) }
    let!(:next_snippet) { create(:snippet, title: "次のコード", category: category) }

    let(:attempt) { create(:attempt, user: user, snippet: current_snippet, level: "hard") }

    before { login_as(user) }

    # 練習画面へ直接飛ばすのではなく、いったん解説を挟む。
    # 次に何を打つのか分からないまま始めることにならないようにする。
    it "次へは次のコードの解説ページに向かう" do
      get attempt_path(attempt)

      expect(response.body).to include(snippet_path(next_snippet))
    end

    it "戻るは前のコードの解説ページに向かう" do
      get attempt_path(attempt)

      expect(response.body).to include(snippet_path(previous_snippet))
    end

    it "移動先のコードの題名を添える" do
      get attempt_path(attempt)

      expect(response.body).to include("次のコード")
      expect(response.body).to include("前のコード")
    end

    context "最初のコードのとき" do
      let(:attempt) { create(:attempt, user: user, snippet: previous_snippet) }

      it "戻る先がないことを知らせる" do
        get attempt_path(attempt)

        expect(response.body).to include("これが最初のコードです。")
      end
    end

    context "最後のコードのとき" do
      let(:attempt) { create(:attempt, user: user, snippet: next_snippet) }

      it "次がないことを知らせる" do
        get attempt_path(attempt)

        expect(response.body).to include("これが最後のコードです")
      end
    end

    context "他の人の採点結果のとき" do
      it "開けない" do
        others = create(:attempt, user: create(:user), snippet: current_snippet)

        expect { get attempt_path(others) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /attempts" do
    let!(:snippet) { create(:snippet, title: "練習したコード") }

    before { login_as(user) }

    it "まだ練習していなければその旨を伝える" do
      get attempts_path

      expect(response.body).to include("まだ練習履歴がありません")
    end

    context "同じコードを何度か練習したとき" do
      before do
        create(:attempt, user: user, snippet: snippet, accuracy: 70, created_at: 2.days.ago)
        create(:attempt, user: user, snippet: snippet, accuracy: 95, created_at: 1.day.ago)
        create(:attempt, :needs_review, user: user, snippet: snippet, created_at: 1.hour.ago)
      end

      it "コードごとに1行だけ並べる" do
        get attempts_path

        expect(response.body.scan("練習したコード").size).to eq(2) # 要復習の欄と履歴の表で1つずつ
      end

      it "挑戦した回数を数える" do
        get attempts_path

        expect(response.body).to include(">3<")
      end

      # 最高が95%でも、直近が要復習なら復習に入れる。
      # 一度できたからもう大丈夫、とはならないため。
      it "直近の結果で要復習かどうかを決める" do
        get attempts_path

        expect(response.body).to include("要復習")
      end
    end
  end
end
