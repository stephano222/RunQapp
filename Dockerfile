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

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]