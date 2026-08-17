module BackgroundHelper
  # 実際の時刻に合わせてトップページの背景を切り替える。
  # 画像が用意できていない時間帯は、近い時間帯のもので代用する。
  TIME_BACKGROUNDS = [
    { from: 5,  to: 10, image: "bg_morning.jpg",  label: "朝" },
    { from: 10, to: 16, image: "bg_day.jpg",      label: "昼" },
    { from: 16, to: 19, image: "bg_evening.jpg",  label: "夕方" },
    { from: 19, to: 23, image: "bg_night.jpg",    label: "夜" },
    { from: 23, to: 5,  image: "bg_midnight.jpg", label: "深夜" }
  ].freeze

  FALLBACK_IMAGE = "bg_day.jpg".freeze

  def background_image_for_now
    hour = Time.current.hour

    entry = TIME_BACKGROUNDS.find do |b|
      if b[:from] < b[:to]
        hour >= b[:from] && hour < b[:to]
      else
        # 深夜のように日をまたぐ範囲
        hour >= b[:from] || hour < b[:to]
      end
    end

    image = entry ? entry[:image] : FALLBACK_IMAGE
    # 未用意の画像を指定してもエラーにせず、代わりの画像を出す
    asset_exists?(image) ? image : FALLBACK_IMAGE
  end

  private

  def asset_exists?(name)
    Rails.application.assets_manifest.assets[name].present?
  rescue StandardError
    Rails.root.join("app/assets/images", name).exist?
  end
end
