FROM ruby:3.2.3

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# 必要最小限のパッケージ
RUN apt-get update -qq && \
    apt-get install -y build-essential default-libmysqlclient-dev pkg-config nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /myapp

# Gemのインストール
COPY Gemfile* ./
RUN bundle install

# JSパッケージのインストール
COPY package.json* ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]