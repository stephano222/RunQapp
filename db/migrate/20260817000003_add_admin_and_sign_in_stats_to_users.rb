class AddAdminAndSignInStatsToUsers < ActiveRecord::Migration[7.0]
  def change
    # 管理画面を見られる人。既定は全員false。
    add_column :users, :admin, :boolean, null: false, default: false

    # ログイン回数と最終ログイン日時。利用状況の把握に使う。
    add_column :users, :sign_in_count, :integer, null: false, default: 0
    add_column :users, :last_sign_in_at, :datetime
  end
end
