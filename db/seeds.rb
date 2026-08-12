# 初期データ: 覚えておきたい重要なRailsコード集
# 既存の公式コード(user_idがnil)だけを入れ替える。ユーザーが追加したコードは消さない。

mvc = Category.find_or_create_by!(name: "MVCの基本構文") { |c| c.position = 1 }
ar  = Category.find_or_create_by!(name: "ActiveRecordクエリ") { |c| c.position = 2 }
cfg = Category.find_or_create_by!(name: "Gemfile・設定コマンド") { |c| c.position = 3 }

Snippet.official.destroy_all

def seed_snippet(category, title, code, explanation)
  Snippet.create!(
    category: category,
    user: nil,
    title: title,
    code: code.strip,
    explanation: explanation.strip,
    language: "ruby"
  )
end

seed_snippet(mvc, "ルーティング(resources)", <<~CODE, <<~EXP)
  resources :posts
CODE
  1行でindex/show/new/create/edit/update/destroyの7つのルーティングを一括生成する。
  一部だけ使う場合は only: [:index, :show] や except: [:destroy] を指定する。
EXP

seed_snippet(mvc, "コントローラのCRUDアクション", <<~CODE, <<~EXP)
  class PostsController < ApplicationController
    def index
      @posts = Post.all
    end

    def show
      @post = Post.find(params[:id])
    end

    def create
      @post = Post.new(post_params)
      if @post.save
        redirect_to @post, notice: "作成しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def post_params
      params.require(:post).permit(:title, :body)
    end
  end
CODE
  Railsコントローラの基本形。saveが成功したらredirect_to、失敗したらrenderしてエラーを表示するのが定番パターン。
  strong parametersでrequire/permitを使い、意図しないパラメータの一括代入を防ぐ。
EXP

seed_snippet(mvc, "バリデーション", <<~CODE, <<~EXP)
  class Post < ApplicationRecord
    validates :title, presence: true, length: { maximum: 100 }
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :price, numericality: { greater_than_or_equal_to: 0 }
  end
CODE
  モデルの保存前チェックを行う。presence(必須)、length(文字数)、format(正規表現)、
  numericality(数値)が特によく使う。validすると保存でき、invalidだとerrorsに理由が入る。
EXP

seed_snippet(mvc, "アソシエーション(関連付け)", <<~CODE, <<~EXP)
  class User < ApplicationRecord
    has_many :posts, dependent: :destroy
  end

  class Post < ApplicationRecord
    belongs_to :user
  end
CODE
  has_manyとbelongs_toはセットで使う。dependent: :destroyで親を消したときに子も一緒に削除する。
  belongs_toは相手のレコードが必須(デフォルト)なので、任意にしたい場合はoptional: trueをつける。
EXP

seed_snippet(mvc, "form_withでのフォーム", <<~CODE, <<~EXP)
  <%= form_with model: @post do |f| %>
    <%= f.text_field :title, class: "form-control" %>
    <%= f.text_area :body, class: "form-control" %>
    <%= f.submit "保存する", class: "btn btn-primary" %>
  <% end %>
CODE
  Rails標準のフォームヘルパー。@postが新規レコードならPOST(create)、
  永続化済みレコードならPATCH(update)へ自動的に送信先を切り替えてくれる。
EXP

seed_snippet(ar, "where / find_by", <<~CODE, <<~EXP)
  User.where(active: true)
  User.where("age >= ?", 20)
  User.find_by(email: "a@example.com")
  User.find(1)
CODE
  whereは条件に合うレコードを複数(Relation)として返し、find_byは1件だけ(なければnil)返す。
  findは主キーで検索し、見つからないとActiveRecord::RecordNotFoundを発生させる。
EXP

seed_snippet(ar, "order / limit", <<~CODE, <<~EXP)
  Post.order(created_at: :desc).limit(10)
CODE
  orderで並び替え、limitで件数を絞る。新着順に10件取得する、というよく使う組み合わせ。
EXP

seed_snippet(ar, "includes(N+1対策)", <<~CODE, <<~EXP)
  posts = Post.includes(:user).where(published: true)
  posts.each { |post| puts post.user.name }
CODE
  includesを使うと関連レコードを事前にまとめて読み込み、N+1問題(ループ内で都度SQLが発行される)を防ぐ。
  eager_load(JOIN)やpreload(別クエリ)と使い分けることもできる。
EXP

seed_snippet(ar, "joins / group / count", <<~CODE, <<~EXP)
  Post.joins(:comments).group("posts.id").count
CODE
  joinsでテーブルを結合し、groupでグループ化、countで集計する。
  「投稿ごとのコメント数」のような集計処理に使う定番の書き方。
EXP

seed_snippet(ar, "scopeの定義", <<~CODE, <<~EXP)
  class Post < ApplicationRecord
    scope :published, -> { where(published: true) }
    scope :recent, -> { order(created_at: :desc) }
  end

  Post.published.recent
CODE
  よく使うクエリ条件に名前を付けて再利用できるようにする書き方。
  scope同士はメソッドチェーンでつなげられる。
EXP

seed_snippet(cfg, "Gemの追加からインストール", <<~CODE, <<~EXP)
  # Gemfileに追記
  gem "rspec-rails"

  # ターミナルで実行
  bundle install
CODE
  Gemfileに使いたいgemを追記してから`bundle install`を実行するのが基本の流れ。
  Gemfile.lockにバージョンが固定され、チーム全員が同じバージョンを使えるようになる。
EXP

seed_snippet(cfg, "DBの作成とマイグレーション", <<~CODE, <<~EXP)
  rails db:create
  rails db:migrate
  rails db:seed
CODE
  db:createでデータベースを作成、db:migrateで保留中のマイグレーションを実行してテーブルを更新、
  db:seedでdb/seeds.rbの初期データを投入する。この3つはセットで覚えておくと便利。
EXP

seed_snippet(cfg, "scaffoldとmodel生成コマンド", <<~CODE, <<~EXP)
  rails g scaffold Post title:string body:text
  rails g model Comment body:text post:references
  rails g migration AddPublishedToPosts published:boolean
CODE
  rails generate(g)コマンドでモデル・コントローラ・ビュー・マイグレーションをまとめて生成できる。
  scaffoldはCRUD一式を丸ごと作り、modelやmigrationは個別に必要なファイルだけ作る。
EXP

seed_snippet(cfg, "よく使う開発コマンド", <<~CODE, <<~EXP)
  rails routes
  rails console
  rails server
CODE
  rails routesで定義済みルーティング一覧を確認、rails console(rails c)で対話的にモデルを操作、
  rails server(rails s)で開発用サーバーを起動する。デバッグ時に頻繁に使う3つ。
EXP

puts "Seed完了: カテゴリ#{Category.count}件 / 公式スニペット#{Snippet.official.count}件"
