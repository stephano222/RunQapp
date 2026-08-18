FactoryBot.define do
  factory :attempt do
    user
    snippet
    level { "normal" }
    input_text { "resources :posts" }
    accuracy { 100.0 }
    mistake_count { 0 }
    duration_ms { 5_000 }
    correct { true }

    # create(:attempt, :needs_review) で「要復習」の記録になる。
    # 境界の値を直に書かず、判定に使っている閾値から導く。
    # 閾値を変えたときにテストが一緒に追随してほしいため。
    trait :needs_review do
      accuracy { Attempt::REVIEW_THRESHOLD - 10 }
      correct { false }
    end
  end
end
