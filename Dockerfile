FROM ruby:3.2.3

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# Node.js リポジトリ登録＋ビルドツール＋PostgreSQLクライアント＋Yarn導入
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get update -qq \
 && apt-get install -y build-essential libpq-dev pkg-config nodejs \
 && npm install --global yarn \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /myapp

# Gemのインストール
COPY Gemfile* ./
RUN bundle install

# JSパッケージのインストール（yarn を使用）
COPY package.json yarn.lock* ./
RUN yarn install

COPY . .

# 本番用アセット(CSS/JS)を事前に生成しておく。
# ここで作らないと本番起動時に application.css が見つからず500になる。
# SECRET_KEY_BASE と DATABASE_URL はビルド時だけのダミー値。
RUN SECRET_KEY_BASE=dummy_for_assets_precompile \
    DATABASE_URL=postgresql://user:pass@localhost/dummy \
    RAILS_ENV=production \
    bundle exec rails assets:precompile && \
    ls public/assets/application-*.css > /dev/null

EXPOSE 3000

ENTRYPOINT ["/myapp/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]