FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    # 並び順もカテゴリごとに違う値にしておく。
    # 同じ position が並ぶと、次のコードを探す順番の検証がしづらくなる。
    sequence(:position) { |n| n }
  end
end
