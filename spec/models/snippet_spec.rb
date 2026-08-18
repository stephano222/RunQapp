require "rails_helper"

# Snippet の「誰に見せるか」と「次にどれを練習するか」を確かめる。
#
# この2つはどちらも、間違えると利用者に直接跳ね返る。
# 前者は他人の書いたコードが見えてしまい、後者は一覧に出ないコードへ
# 飛ばしてしまう。目で見て気づきにくいので、ここで固めておく。
RSpec.describe Snippet do
  # describe は「何について」、context は「どういうときに」、
  # it は「どうなるか」を書く。この3つで文章として読める形にする。
  describe ".visible_to" do
    # let は、その名前が最初に呼ばれたときに一度だけ作られる。
    # 使わないテストでは作られないので、無駄がない。
    let(:taro) { create(:user) }
    let(:hanako) { create(:user) }

    let!(:official) { create(:snippet, title: "公式のコード") }
    let!(:taro_snippet) { create(:snippet, title: "太郎のコード", user: taro) }
    let!(:hanako_snippet) { create(:snippet, title: "花子のコード", user: hanako) }

    it "最初から入っている公式のコードは誰にでも見せる" do
      expect(described_class.visible_to(taro)).to include(official)
      expect(described_class.visible_to(hanako)).to include(official)
    end

    it "自分で追加したコードは自分には見せる" do
      expect(described_class.visible_to(taro)).to include(taro_snippet)
    end

    it "他の人が追加したコードは見せない" do
      expect(described_class.visible_to(taro)).not_to include(hanako_snippet)
      expect(described_class.visible_to(hanako)).not_to include(taro_snippet)
    end

    context "ログインしていないとき" do
      it "公式のコードだけを見せる" do
        expect(described_class.visible_to(nil)).to contain_exactly(official)
      end
    end
  end

  describe "#next_in_course / #prev_in_course" do
    let(:user) { create(:user) }

    # 並び順は「カテゴリの position 順 → コードの id 順」で決まる。
    # それを確かめたいので、カテゴリを2つ用意して順番を明示しておく。
    let(:first_category) { create(:category, position: 1) }
    let(:second_category) { create(:category, position: 2) }

    let!(:a) { create(:snippet, title: "1つ目", category: first_category) }
    let!(:b) { create(:snippet, title: "2つ目", category: first_category) }
    let!(:c) { create(:snippet, title: "3つ目", category: second_category) }

    it "同じカテゴリの中では次のコードへ進む" do
      expect(a.next_in_course(user)).to eq(b)
    end

    it "カテゴリの最後まで来たら次のカテゴリの先頭へ進む" do
      expect(b.next_in_course(user)).to eq(c)
    end

    it "最後のコードには次がない" do
      expect(c.next_in_course(user)).to be_nil
    end

    it "戻るときは進むときの逆をたどる" do
      expect(c.prev_in_course(user)).to eq(b)
      expect(b.prev_in_course(user)).to eq(a)
    end

    it "最初のコードには前がない" do
      expect(a.prev_in_course(user)).to be_nil
    end

    it "進んでから戻ると元の位置に帰ってくる" do
      expect(a.next_in_course(user).prev_in_course(user)).to eq(a)
    end

    context "他の人が追加したコードが間に挟まっているとき" do
      let(:another_user) { create(:user) }
      let!(:hidden) { create(:snippet, title: "他人のコード", category: first_category, user: another_user) }

      # hidden は a と b より後に作られたので id が大きい。
      # つまり並び順では b の次に来るが、この利用者の一覧には出ない。
      it "一覧に出ないコードは飛ばして進む" do
        expect(b.next_in_course(user)).to eq(c)
      end

      it "本人が見るときは飛ばさずに進む" do
        expect(b.next_in_course(another_user)).to eq(hidden)
      end
    end
  end

  describe "#official?" do
    it "追加した人がいなければ公式のコードとして扱う" do
      expect(create(:snippet).official?).to be true
    end

    it "追加した人がいれば公式ではない" do
      expect(create(:snippet, user: create(:user)).official?).to be false
    end
  end

  describe "#editable_by?" do
    let(:owner) { create(:user) }
    let(:snippet) { create(:snippet, user: owner) }

    it "追加した本人は直せる" do
      expect(snippet.editable_by?(owner)).to be true
    end

    it "別の人は直せない" do
      expect(snippet.editable_by?(create(:user))).to be false
    end

    it "公式のコードは誰も直せない" do
      expect(create(:snippet).editable_by?(owner)).to be false
    end
  end
end
