#!/usr/bin/env bash
# Render用ビルドスクリプト
set -o errexit

bundle install

# JSの依存関係を入れる(yarnが無い環境ではnpmにフォールバック)
if command -v yarn > /dev/null 2>&1; then
  yarn install --frozen-lockfile
else
  echo "yarn が見つからないため npm を使います"
  npm install
fi

# CSS(dartsass)とJS(esbuild)を明示的にビルドしてから配信用にまとめる
bundle exec rails dartsass:build
bundle exec rails javascript:build
bundle exec rails assets:precompile
bundle exec rails assets:clean

# ビルド結果を検証する。ここで落とせば起動後の500ではなくビルド失敗として気付ける
if ! ls public/assets/application-*.css > /dev/null 2>&1; then
  echo "ERROR: application.css が生成されていません。dartsass のビルドを確認してください。"
  exit 1
fi
echo "OK: application.css を生成しました"

bundle exec rails db:migrate
bundle exec rails db:seed
