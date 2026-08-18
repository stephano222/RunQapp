require "rails_helper"

RSpec.describe Category do
  describe "並び順" do
    # 一覧・カテゴリ画面・「次へ」の移動先が、すべてこの順に従う。
    # ここが崩れると画面ごとに順番が食い違う。
    it "position の小さい順に並べる" do
      third = create(:category, position: 3)
      first = create(:category, position: 1)
      second = create(:category, position: 2)

      expect(described_class.all.to_a).to eq([first, second, third])
    end

    it "position が同じなら作った順に並べる" do
      older = create(:category, position: 1)
      newer = create(:category, position: 1)

      expect(described_class.all.to_a).to eq([older, newer])
    end
  end

  describe "入力の検査" do
    it "名前がなければ保存しない" do
      expect(build(:category, name: "")).not_to be_valid
    end

    it "同じ名前は2つ作れない" do
      create(:category, name: "ルーティング")

      expect(build(:category, name: "ルーティング")).not_to be_valid
    end
  end

  describe "カテゴリを消したとき" do
    # 中身ごと消える。カテゴリ名の整理のつもりで消すと、
    # 利用者の練習記録まで失われることを、ここで明示しておく。
    it "そこに属するコードも一緒に消える" do
      category = create(:category)
      create(:snippet, category: category)

      expect { category.destroy }.to change(Snippet, :count).by(-1)
    end

    it "そのコードの練習記録も一緒に消える" do
      category = create(:category)
      create(:attempt, snippet: create(:snippet, category: category))

      expect { category.destroy }.to change(Attempt, :count).by(-1)
    end
  end
end
