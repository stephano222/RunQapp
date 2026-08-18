require "rails_helper"

# 続けた記録の数え方。
# 日付をまたぐ数え方は取り違えやすいので、境目を一つずつ確かめる。
RSpec.describe User, "続けた記録" do
  let(:user) { create(:user) }
  let(:today) { Date.new(2026, 8, 19) } # 水曜日

  # 指定した日に練習した記録を作る。
  # 時刻は昼にしておく。深夜だと時差の扱いで前日に寄る可能性があるため、
  # 境目そのものは別のテストで確かめる。
  def practiced_on(date)
    create(:attempt, user: user, created_at: Time.zone.parse("#{date} 12:00"))
  end

  describe "#practice_streak" do
    it "一度も練習していなければ0" do
      expect(user.practice_streak(today)).to eq(0)
    end

    it "今日だけ練習していれば1" do
      practiced_on(today)

      expect(user.practice_streak(today)).to eq(1)
    end

    it "今日から続いている日数を数える" do
      [today, today - 1, today - 2].each { |d| practiced_on(d) }

      expect(user.practice_streak(today)).to eq(3)
    end

    it "同じ日に何度やっても1日と数える" do
      3.times { practiced_on(today) }

      expect(user.practice_streak(today)).to eq(1)
    end

    # 日付が変わった瞬間に0へ戻ると、続ける気をくじいてしまう。
    it "今日まだでも昨日やっていれば途切れない" do
      [today - 1, today - 2].each { |d| practiced_on(d) }

      expect(user.practice_streak(today)).to eq(2)
    end

    it "一昨日で止まっていれば途切れたとみなす" do
      [today - 2, today - 3].each { |d| practiced_on(d) }

      expect(user.practice_streak(today)).to eq(0)
    end

    it "途中で一日空いていればそこまでで止める" do
      [today, today - 1, today - 3, today - 4].each { |d| practiced_on(d) }

      expect(user.practice_streak(today)).to eq(2)
    end

    it "月をまたいでも続いていれば数える" do
      first_of_month = Date.new(2026, 9, 1)
      [first_of_month, first_of_month - 1, first_of_month - 2].each { |d| practiced_on(d) }

      expect(user.practice_streak(first_of_month)).to eq(3)
    end

    context "日付の境目のとき" do
      # 記録は世界時で保存されるが、数えるのは日本時間の日付で行う。
      # 取り違えると、深夜の練習が前日に入ってしまう。
      it "日本時間の深夜0時すぎはその日として数える" do
        create(:attempt, user: user, created_at: Time.zone.parse("#{today} 00:30"))

        expect(user.practice_streak(today)).to eq(1)
      end

      it "日本時間の23時台もその日として数える" do
        create(:attempt, user: user, created_at: Time.zone.parse("#{today} 23:30"))

        expect(user.practice_streak(today)).to eq(1)
      end
    end
  end

  describe "#attempts_this_week" do
    it "今週やった問題数を数える" do
      practiced_on(today)
      practiced_on(today - 1)

      expect(user.attempts_this_week(today)).to eq(2)
    end

    it "同じ日に何度やった分もそれぞれ数える" do
      3.times { practiced_on(today) }

      expect(user.attempts_this_week(today)).to eq(3)
    end

    it "先週の分は含めない" do
      practiced_on(today.beginning_of_week - 1) # 前の週の日曜

      expect(user.attempts_this_week(today)).to eq(0)
    end

    it "週の初日である月曜の分は含める" do
      practiced_on(today.beginning_of_week)

      expect(user.attempts_this_week(today)).to eq(1)
    end
  end

  describe "#practiced_days_this_week" do
    it "今週のうち練習した日だけを返す" do
      monday = today.beginning_of_week
      practiced_on(monday)
      practiced_on(today)

      expect(user.practiced_days_this_week(today)).to contain_exactly(monday, today)
    end

    it "先週の分は含めない" do
      practiced_on(today.beginning_of_week - 1)

      expect(user.practiced_days_this_week(today)).to be_empty
    end
  end
end
