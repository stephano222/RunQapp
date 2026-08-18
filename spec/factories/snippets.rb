FactoryBot.define do
  factory :snippet do
    sequence(:title) { |n| "コード#{n}" }
    code { "resources :posts" }
    category
    # user を指定しなければ nil のまま。つまり既定は公式のコードになる。
    # 誰かが追加したコードにしたいときは create(:snippet, user: 太郎) と渡す。
    user { nil }
  end
end
