# 死活監視用のエンドポイント。
#
# ログイン不要・DB接続なし・ビューの描画なしで即座に応答する。
# 監視サービスから定期的に叩かれても負荷にならないよう、
# できるだけ何もしない作りにしている。
class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def show
    render plain: "ok", status: :ok
  end
end
