require "rails_helper"

# 今日やるとよいコードの選び方。
#
# 間違えると「昨日やったばかりのものが毎日出る」「できないものが
# 30日後まで出てこない」といった、続ける気を削ぐ形になる。
# 日数の境目を一つずつ確かめる。
RSpec.describe PracticeRecommender do
  let(:user) { create(:user) }
  let(:today) { Date.new(2026, 8, 19) }
  let(:category) { create(:category, position: 1) }

  def recommend(limit: 5)
    described_class.new(user, today: today).due(limit: limit)
  end

  # 指定した日に、指定の正答率で練習した記録を作る
  def practiced(snippet, days_ago:, accuracy: 100)
    create(:attempt, user: user, snippet: snippet, accuracy: accuracy,
                     created_at: Time.zone.parse("#{today - days_ago} 12:00"))
  end

  describe "まだ打っていないコード" do
    it "勧める" do
      snippet = create(:snippet, title: "はじめてのコード", category: category)

      expect(recommend.map(&:snippet)).to include(snippet)
    end

    it "はじめてだと分かる理由を添える" do
      create(:snippet, category: category)

      expect(recommend.first.reason).to eq("はじめて")
    end

    it "優しいレベルから始める" do
      create(:snippet, category: category)

      expect(recommend.first.level).to eq("easy")
    end

    it "他の人が追加したコードは勧めない" do
      create(:snippet, title: "他人のコード", category: category, user: create(:user))

      expect(recommend).to be_empty
    end
  end

  describe "復習の間隔" do
    let(:snippet) { create(:snippet, category: category) }

    context "前回できなかったとき" do
      # できなかったものを何日も寝かせると、そのまま忘れてしまう。
      it "翌日には勧める" do
        practiced(snippet, days_ago: 1, accuracy: 60)

        expect(recommend.map(&:snippet)).to include(snippet)
      end

      it "同じ日にやったばかりなら勧めない" do
        practiced(snippet, days_ago: 0, accuracy: 60)

        expect(recommend.map(&:snippet)).not_to include(snippet)
      end

      it "前回の正答率を理由に出す" do
        practiced(snippet, days_ago: 1, accuracy: 62)

        expect(recommend.first.reason).to eq("前回62%")
      end
    end

    context "一度できたとき" do
      # 合格1回で間隔は3日。翌日にまた出すと、できたものを繰り返すことになる。
      it "翌日は勧めない" do
        practiced(snippet, days_ago: 1, accuracy: 100)

        expect(recommend.map(&:snippet)).not_to include(snippet)
      end

      it "3日経てば勧める" do
        practiced(snippet, days_ago: 3, accuracy: 100)

        expect(recommend.map(&:snippet)).to include(snippet)
      end
    end

    context "何度もできているとき" do
      # 合格を重ねるほど間隔を広げ、空いた分を他のコードに回す。
      it "3日では勧めない" do
        3.times { |i| practiced(snippet, days_ago: 10 + i, accuracy: 100) }
        practiced(snippet, days_ago: 3, accuracy: 100)

        expect(recommend.map(&:snippet)).not_to include(snippet)
      end

      it "十分に日が空けば勧める" do
        4.times { |i| practiced(snippet, days_ago: 40 + i, accuracy: 100) }
        practiced(snippet, days_ago: 31, accuracy: 100)

        expect(recommend.map(&:snippet)).to include(snippet)
      end
    end

    context "できていたのに落としたとき" do
      # 積み上げた間隔を維持すると、できなくなったものが
      # 30日後まで出てこない。一度戻す。
      it "翌日には勧める" do
        4.times { |i| practiced(snippet, days_ago: 20 + i, accuracy: 100) }
        practiced(snippet, days_ago: 1, accuracy: 55)

        expect(recommend.map(&:snippet)).to include(snippet)
      end
    end

    it "しばらく空いていればその日数を理由に出す" do
      practiced(snippet, days_ago: 10, accuracy: 100)

      expect(recommend.first.reason).to eq("10日ぶり")
    end
  end

  describe "並び順" do
    it "期限を過ぎたものを、まだ打っていないものより先に出す" do
      overdue = create(:snippet, title: "期限切れ", category: category)
      practiced(overdue, days_ago: 5, accuracy: 60)
      create(:snippet, title: "はじめて", category: category)

      expect(recommend.first.snippet).to eq(overdue)
    end

    it "遅れの大きいものを先に出す" do
      late = create(:snippet, title: "大きく遅れ", category: category)
      slight = create(:snippet, title: "少し遅れ", category: category)
      practiced(late, days_ago: 30, accuracy: 60)
      practiced(slight, days_ago: 2, accuracy: 60)

      expect(recommend.map { |r| r.snippet.title }.first(2)).to eq(["大きく遅れ", "少し遅れ"])
    end

    it "遅れが同じなら正答率の低いほうを先に出す" do
      worse = create(:snippet, title: "苦手", category: category)
      better = create(:snippet, title: "まあまあ", category: category)
      practiced(worse, days_ago: 5, accuracy: 40)
      practiced(better, days_ago: 5, accuracy: 80)

      expect(recommend.map { |r| r.snippet.title }.first(2)).to eq(["苦手", "まあまあ"])
    end
  end

  describe "件数" do
    it "指定した数までしか返さない" do
      create_list(:snippet, 10, category: category)

      expect(recommend(limit: 5).size).to eq(5)
    end

    it "全部やり終えて期限も来ていなければ空になる" do
      snippet = create(:snippet, category: category)
      practiced(snippet, days_ago: 0, accuracy: 100)

      expect(recommend).to be_empty
    end

    it "コードが一つも無くても落ちない" do
      expect { recommend }.not_to raise_error
    end
  end

  describe "前回のレベルを引き継ぐ" do
    it "普通で解いたものは普通で勧める" do
      snippet = create(:snippet, category: category)
      create(:attempt, user: user, snippet: snippet, level: "normal", accuracy: 60,
                       created_at: Time.zone.parse("#{today - 3} 12:00"))

      expect(recommend.first.level).to eq("normal")
    end
  end

  describe "他の人の記録" do
    it "自分の練習だけを見る" do
      snippet = create(:snippet, category: category)
      create(:attempt, user: create(:user), snippet: snippet, accuracy: 100,
                       created_at: Time.zone.parse("#{today} 12:00"))

      # 他人がやっただけなので、自分にとっては未挑戦のまま
      expect(recommend.first.reason).to eq("はじめて")
    end
  end
end
