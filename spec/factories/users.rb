# テスト用の User を組み立てる型。
#
# create(:user) だけで妥当な利用者が1人できる。
# 一部だけ変えたいときは create(:user, name: "太郎") のように上書きする。
FactoryBot.define do
  factory :user do
    name { "テスト太郎" }
    # メールアドレスは重複できないので、作るたびに違う値になるようにする。
    # sequence は 1, 2, 3... と順に増える番号を渡してくれる。
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password1234" }

    # create(:user, :admin) と書くと管理者になる。
    trait :admin do
      admin { true }
    end
  end
end
