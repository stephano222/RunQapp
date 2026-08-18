require "rails_helper"

RSpec.describe Attempt do
  describe "#needs_review?" do
    # 閾値そのものを書かず、定数から導く。
    # 90から85に変えたときに、テストが一緒に追随してほしいため。
    it "閾値ちょうどなら復習に入れない" do
      attempt = build(:attempt, accuracy: Attempt::REVIEW_THRESHOLD)

      expect(attempt.needs_review?).to be false
    end

    it "閾値をわずかに下回れば復習に入れる" do
      attempt = build(:attempt, accuracy: Attempt::REVIEW_THRESHOLD - 0.1)

      expect(attempt.needs_review?).to be true
    end

    it "満点なら復習に入れない" do
      expect(build(:attempt, accuracy: 100).needs_review?).to be false
    end

    it "0点なら復習に入れる" do
      expect(build(:attempt, accuracy: 0).needs_review?).to be true
    end
  end

  describe "#level_label" do
    it "3つのレベルそれぞれに日本語を返す" do
      expect(build(:attempt, level: "easy").level_label).to eq("優しい")
      expect(build(:attempt, level: "normal").level_label).to eq("普通")
      expect(build(:attempt, level: "hard").level_label).to eq("難しい")
    end
  end

  describe "入力の検査" do
    it "打った内容が空なら保存しない" do
      expect(build(:attempt, input_text: "")).not_to be_valid
    end

    it "正答率が100を超えたら保存しない" do
      expect(build(:attempt, accuracy: 100.1)).not_to be_valid
    end

    it "正答率が0未満なら保存しない" do
      expect(build(:attempt, accuracy: -1)).not_to be_valid
    end

    it "ミス数が負なら保存しない" do
      expect(build(:attempt, mistake_count: -1)).not_to be_valid
    end

    it "かかった時間が負なら保存しない" do
      expect(build(:attempt, duration_ms: -1)).not_to be_valid
    end

    it "誰の記録か分からなければ保存しない" do
      expect(build(:attempt, user: nil)).not_to be_valid
    end

    it "どのコードの記録か分からなければ保存しない" do
      expect(build(:attempt, snippet: nil)).not_to be_valid
    end
  end

  describe "コードが消されたとき" do
    # 記録だけが残ると、題名を引けずに画面が壊れる。
    it "そのコードの練習記録も一緒に消える" do
      snippet = create(:snippet)
      create(:attempt, snippet: snippet)

      expect { snippet.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
