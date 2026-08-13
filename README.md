# RunQの森

重要なRailsコードを「打って覚える」タイピング練習アプリです。
MVCの基本構文・ActiveRecordクエリ・Gemfile/設定コマンドなど、実務でよく使うコードを
優しい(なぞる)・普通(ヒントあり)・難しい(ノーヒント)の3段階で練習できます。
ログインすれば自分の好きなコードを追加して練習することも可能です。

## セットアップ

```bash
docker compose up -d
docker compose exec web bundle exec rails db:create db:migrate db:seed
```

起動後は http://localhost:3001 でアクセスできます(compose.ymlのポート設定に依存)。
