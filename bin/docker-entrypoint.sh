#!/usr/bin/env bash
# コンテナ起動時の共通処理。
# 本番(Renderなど)ではDBの準備がビルド時にできないので、起動直前にここで行う。
set -e

if [ "${RAILS_ENV}" = "production" ]; then
  echo "[entrypoint] マイグレーションを実行します"
  bundle exec rails db:migrate

  echo "[entrypoint] シードデータを投入します"
  bundle exec rails db:seed
fi

exec "$@"
