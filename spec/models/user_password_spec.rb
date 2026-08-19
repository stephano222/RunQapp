require "rails_helper"

RSpec.describe User, "パスワードの条件" do
  describe "長さ" do
    it "下限に満たなければ登録できない" do
      user = build(:user, password: "a" * (User::MINIMUM_PASSWORD_LENGTH - 1))

      expect(user).not_to be_valid
    end

    it "下限ちょうどなら登録できる" do
      user = build(:user, password: "kaminari" * 1) # 8文字

      expect(user).to be_valid
    end

    it "長いぶんには構わない" do
      expect(build(:user, password: "a" * 60)).to be_valid
    end

    # bcrypt は72バイトまでしか見ない。それを超える分は無視されるため、
    # Rails 側が上限として弾く。長い合言葉を使う人が引っかかりうる。
    it "72文字を超えるものは断る" do
      expect(build(:user, password: "a" * 73)).not_to be_valid
    end
  end

  describe "よく使われるパスワード" do
    # 長さを満たしていても、流出一覧の上位にあるものは
    # 総当たりで真っ先に試される。
    it "password は断る" do
      expect(build(:user, password: "password")).not_to be_valid
    end

    it "12345678 は断る" do
      expect(build(:user, password: "12345678")).not_to be_valid
    end

    it "大文字に変えただけのものも断る" do
      expect(build(:user, password: "PassWord")).not_to be_valid
    end

    it "断る理由を伝える" do
      user = build(:user, password: "password")
      user.valid?

      expect(user.errors[:password].join).to include("よく使われていて危険です")
    end

    it "一覧にない文字列なら通す" do
      expect(build(:user, password: "runq-mori-taiken")).to be_valid
    end

    # ゲスト用のパスワードが条件に引っかかると、シードが流れなくなる。
    it "ゲスト用のパスワードは条件を満たしている" do
      expect(build(:user, password: User::GUEST_PASSWORD)).to be_valid
    end
  end

  describe "変更しないとき" do
    # 名前だけ直す場面。パスワードの検査が走って弾かれては困る。
    it "パスワードを触らなければ検査しない" do
      user = create(:user, password: "runq-mori-taiken")

      expect(user.update(name: "新しい名前")).to be true
    end
  end
end
