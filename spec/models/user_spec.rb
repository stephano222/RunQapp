require "rails_helper"

RSpec.describe User do
  describe "#sync_admin_flag!" do
    # 環境変数を書き換えるので、テストが終わったら必ず元に戻す。
    # 戻し忘れると、後から動く別のテストに影響が残る。
    around do |example|
      original = ENV["ADMIN_EMAIL"]
      example.run
      ENV["ADMIN_EMAIL"] = original
    end

    let(:user) { create(:user, email: "admin@example.com") }

    it "指定されたアドレスなら管理者にする" do
      ENV["ADMIN_EMAIL"] = "admin@example.com"

      expect { user.sync_admin_flag! }.to change { user.reload.admin? }.from(false).to(true)
    end

    # 実際にあった不具合。管理画面に貼り付けた値の前後に空白が混ざり、
    # 一致せずに静かに失敗していた。
    it "前後の空白や大文字小文字の違いは無視する" do
      ENV["ADMIN_EMAIL"] = "  Admin@Example.com \n"

      user.sync_admin_flag!

      expect(user.reload.admin?).to be true
    end

    it "指定と違うアドレスなら管理者にしない" do
      ENV["ADMIN_EMAIL"] = "someone@example.com"

      user.sync_admin_flag!

      expect(user.reload.admin?).to be false
    end

    it "指定から外れた人からは管理者権限を取り上げる" do
      admin = create(:user, :admin, email: "old@example.com")
      ENV["ADMIN_EMAIL"] = "new@example.com"

      admin.sync_admin_flag!

      expect(admin.reload.admin?).to be false
    end

    context "ADMIN_EMAIL が設定されていないとき" do
      # 設定を消しただけで管理画面に入れなくなると、復旧できなくなる。
      it "既にある権限には手を触れない" do
        admin = create(:user, :admin)
        ENV["ADMIN_EMAIL"] = nil

        admin.sync_admin_flag!

        expect(admin.reload.admin?).to be true
      end
    end
  end

  describe "#record_sign_in!" do
    let(:user) { create(:user) }

    it "ログインした回数を1つ増やす" do
      expect { user.record_sign_in! }.to change { user.reload.sign_in_count }.by(1)
    end

    it "最後にログインした日時を記録する" do
      user.record_sign_in!

      expect(user.reload.last_sign_in_at).to be_present
    end
  end

  describe "メールアドレスの扱い" do
    it "保存するときに小文字へ揃える" do
      user = create(:user, email: "Taro@Example.COM")

      expect(user.email).to eq("taro@example.com")
    end

    it "同じアドレスでは2人登録できない" do
      create(:user, email: "taro@example.com")
      duplicate = build(:user, email: "taro@example.com")

      expect(duplicate).not_to be_valid
    end
  end
end
