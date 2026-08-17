module BackgroundHelper
  # 実際の時刻に合わせて背景を切り替える。
  # 背景には2種類あり、用途で使い分ける。
  #   鮮明版  : ログイン前のトップページ。写真をはっきり見せる
  #   透明化版: それ以外の全ページ。文字を読みやすくするため色を薄くしてある
  TIME_SLOTS = [
    { from: 5,  to: 10, key: "morning" },
    { from: 10, to: 16, key: "day" },
    { from: 16, to: 19, key: "evening" },
    { from: 19, to: 23, key: "night" },
    { from: 23, to: 5,  key: "midnight" }
  ].freeze

  FALLBACK_KEY = "day".freeze

  def background_image_for_now(vivid: false)
    key = current_time_slot_key
    prefix = vivid ? "bg_" : "bg_soft_"

    candidate = "#{prefix}#{key}.jpg"
    return candidate if background_asset_exists?(candidate)

    # 用意できていない時間帯は昼で代用する
    "#{prefix}#{FALLBACK_KEY}.jpg"
  end

  private

  def current_time_slot_key
    hour = Time.current.hour

    slot = TIME_SLOTS.find do |s|
      if s[:from] < s[:to]
        hour >= s[:from] && hour < s[:to]
      else
        # 深夜のように日をまたぐ範囲
        hour >= s[:from] || hour < s[:to]
      end
    end

    slot ? slot[:key] : FALLBACK_KEY
  end

  def background_asset_exists?(name)
    Rails.root.join("app/assets/images", name).exist?
  end
end
