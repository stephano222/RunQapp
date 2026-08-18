require "rails_helper"

RSpec.describe Snippet, ".search_by_title" do
  let!(:validation) { create(:snippet, title: "バリデーション(入力チェック)") }
  let!(:association) { create(:snippet, title: "アソシエーション(1対多)") }
  let!(:resources) { create(:snippet, title: "resources(7つのルート)") }

  it "題名の一部で絞り込める" do
    expect(described_class.search_by_title("バリデーション")).to contain_exactly(validation)
  end

  it "題名の途中の言葉でも見つかる" do
    expect(described_class.search_by_title("入力")).to contain_exactly(validation)
  end

  it "大文字と小文字は区別しない" do
    expect(described_class.search_by_title("RESOURCES")).to contain_exactly(resources)
  end

  it "複数一致すればすべて返す" do
    expect(described_class.search_by_title("ション")).to contain_exactly(validation, association)
  end

  it "一致しなければ空になる" do
    expect(described_class.search_by_title("存在しない言葉")).to be_empty
  end

  context "絞り込む言葉がないとき" do
    it "空文字なら全部返す" do
      expect(described_class.search_by_title("")).to match_array([validation, association, resources])
    end

    it "空白だけでも全部返す" do
      expect(described_class.search_by_title("　 ")).to match_array([validation, association, resources])
    end

    it "指定なしでも全部返す" do
      expect(described_class.search_by_title(nil)).to match_array([validation, association, resources])
    end
  end

  context "検索の記号が入力されたとき" do
    # % は「何にでも一致する」記号として解釈されるため、
    # そのまま渡すと全件が返ってしまう。文字として扱う必要がある。
    let!(:percent) { create(:snippet, title: "100%達成") }

    it "%はそれ自体を探す文字として扱う" do
      expect(described_class.search_by_title("%")).to contain_exactly(percent)
    end

    it "_もそれ自体を探す文字として扱う" do
      underscore = create(:snippet, title: "before_action")

      expect(described_class.search_by_title("re_ac")).to contain_exactly(underscore)
    end
  end

  it "前後の空白は無視して探す" do
    expect(described_class.search_by_title("  バリデーション  ")).to contain_exactly(validation)
  end

  it "他の絞り込みと重ねられる" do
    user = create(:user)
    mine = create(:snippet, title: "バリデーションの自作メモ", user: user)

    result = described_class.visible_to(user).search_by_title("バリデーション")

    expect(result).to contain_exactly(validation, mine)
  end
end
