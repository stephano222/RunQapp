# 初期データ: 覚えておきたい重要なRailsコード集
# 既存の公式コード(user_idがnil)だけを入れ替える。ユーザーが追加したコードは消さない。

# 誰でも試せるテストユーザー(ログイン画面に初めから入力されている)
test_user = User.find_or_initialize_by(email: "test@example.com")
test_user.name = "テストユーザー"
test_user.password = "test1234"
test_user.save!

# 既存カテゴリでも並び順を確実に反映させるため find_or_create_by! ではなく明示的に更新する
def upsert_category(name, position)
  category = Category.find_or_initialize_by(name: name)
  category.position = position
  category.save!
  category
end

routing = upsert_category("ルーティング", 1)
mvc     = upsert_category("コントローラ", 2)
model   = upsert_category("モデル・バリデーション", 3)
ar      = upsert_category("ActiveRecordクエリ", 4)
migrate = upsert_category("マイグレーション", 5)
view    = upsert_category("ビュー・フォーム", 6)
auth    = upsert_category("認証・セキュリティ", 7)
spec    = upsert_category("テスト(RSpec)", 8)
cfg     = upsert_category("コマンド・設定", 9)
html    = upsert_category("HTML", 10)
setup   = upsert_category("番外編: 環境構築", 11)
deploy  = upsert_category("番外編: デプロイ", 12)

Snippet.official.destroy_all

def seed_snippet(category, title, code, explanation, language = "ruby")
  Snippet.create!(
    category: category,
    user: nil,
    title: title,
    code: code.strip,
    explanation: explanation.strip,
    language: language
  )
end

# ============================================================
# ルーティング
# ============================================================

seed_snippet(routing, "resources(7つのルートを一括生成)", <<~CODE, <<~EXP)
  resources :posts
CODE
  この1行だけで index / show / new / create / edit / update / destroy の7アクション分の
  ルーティングが作られる。Railsが「効率的」と言われる象徴のような記法。

  【重要】必要なものだけに絞るのが実務の基本。
  余計なルートを開けたままだと、意図しないURLにアクセスされる原因になる。
    resources :posts, only: [:index, :show]
    resources :posts, except: [:destroy]

  確認するときは `rails routes` を実行すると、生成された全ルートが一覧で見られる。
EXP

seed_snippet(routing, "ルートパス(トップページ)", <<~CODE, <<~EXP)
  root "posts#index"
CODE
  「/」にアクセスされたときに表示するページを決める。
  `コントローラ名#アクション名` の形式で書く。

  【重要】このルートには自動で `root_path` というヘルパーが作られる。
  ビューでは `link_to "ホーム", root_path` のように使え、
  URLを直書きしないので後からURL構造を変えても壊れない。
EXP

seed_snippet(routing, "member と collection", <<~CODE, <<~EXP)
  resources :posts do
    member do
      get :preview
    end
    collection do
      get :search
    end
  end
CODE
  resourcesの7つ以外に、独自のアクションを追加したいときに使う。

  【重要】2つの違いは「特定の1件に対する操作か、一覧全体に対する操作か」。
    member     → /posts/1/preview  (idが付く。特定の投稿に対して)
    collection → /posts/search     (idが付かない。投稿全体に対して)

  「この投稿をプレビュー」ならmember、「投稿を検索」ならcollection、と考えると迷わない。
EXP

seed_snippet(routing, "ネストしたルーティング", <<~CODE, <<~EXP)
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end
CODE
  「投稿に属するコメント」のような親子関係をURLで表現する。
  生成されるURLは /posts/1/comments となり、どの投稿へのコメントかが明確になる。

  【重要】コントローラ側では `params[:post_id]` で親のIDを受け取れる。
    @post = Post.find(params[:post_id])

  ネストは1段までにするのが定石。2段以上はURLが長くなり扱いづらくなる。
EXP

seed_snippet(routing, "namespace(管理画面などの区分け)", <<~CODE, <<~EXP)
  namespace :admin do
    resources :users
  end
CODE
  URLが /admin/users になり、対応するコントローラは
  `app/controllers/admin/users_controller.rb` に置く(Admin::UsersController)。

  【重要】管理者専用ページを一箇所にまとめるときの定番。
  ファイルもURLも分離されるので、一般ユーザー向け機能と混ざらず見通しが良くなる。
EXP

# ============================================================
# コントローラ
# ============================================================

seed_snippet(mvc, "基本のCRUDアクション", <<~CODE, <<~EXP)
  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end
CODE
  Railsコントローラで最も頻繁に書く形。丸暗記して良いレベルの定型文。

  【重要】成功時と失敗時で処理が違う点が肝。
    成功 → redirect_to(別のURLへ移動させる)
    失敗 → render(入力内容を保持したまま画面を再表示する)

  失敗時にredirectしてしまうと、ユーザーが入力した内容が消えてしまう。
  `status: :unprocessable_entity` はRails 7で必須。これが無いとエラーが画面に出ない。
EXP

seed_snippet(mvc, "ストロングパラメータ", <<~CODE, <<~EXP)
  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
CODE
  フォームから送られてきた値のうち、保存を許可するカラムを明示する仕組み。

  【重要】これはセキュリティ機能。書かないとRailsがエラーにする。
  もし全ての値を無条件に受け入れると、フォームに無い項目(例: admin=true)を
  悪意のあるユーザーに送信され、権限を乗っ取られる恐れがある。

    require → 必須のキー(この中身だけ見る)
    permit  → 許可するカラム(ここに無い項目は無視される)
EXP

seed_snippet(mvc, "before_action(共通処理をまとめる)", <<~CODE, <<~EXP)
  before_action :set_post, only: [:show, :edit, :update]

  private

  def set_post
    @post = Post.find(params[:id])
  end
CODE
  複数のアクションで共通して行う処理を、事前に1箇所で実行する仕組み。

  【重要】同じ `Post.find(params[:id])` を各アクションに書くとコードが重複する。
  before_actionにまとめると、修正が1箇所で済む。

    only:   → 指定したアクションだけで実行
    except: → 指定したアクション以外で実行

  ログイン必須のチェック(`before_action :require_login`)も同じ仕組みで実現する。
EXP

seed_snippet(mvc, "flash メッセージ", <<~CODE, <<~EXP)
  redirect_to posts_path, notice: "保存しました"
  redirect_to posts_path, alert: "権限がありません"
CODE
  次の画面に一度だけ表示されるメッセージ。表示されると自動で消える。

  【重要】redirectとrenderで書き方が変わる点に注意。
    redirect_to ... , notice: "..."  → 次のリクエストで表示
    flash.now[:alert] = "..."        → 今表示している画面で使う(renderの場合)

  renderで `flash[:alert]` を使うと、次のページにも残ってしまい二重に表示される。
EXP

seed_snippet(mvc, "params の受け取り方", <<~CODE, <<~EXP)
  params[:id]
  params[:post][:title]
  params[:q]
CODE
  URLやフォームから送られてきた値を受け取る箱。全てのコントローラで使う。

  【重要】値がどこから来るかで3種類ある。
    /posts/5        → params[:id]      (ルーティングから)
    ?q=rails        → params[:q]       (URLのクエリ文字列から)
    フォーム送信      → params[:post][:title] (フォームの入力欄から)

  受け取った値は必ず文字列。数値として使うなら `.to_i` が必要。
EXP

# ============================================================
# モデル・バリデーション
# ============================================================

seed_snippet(model, "バリデーション(入力チェック)", <<~CODE, <<~EXP)
  validates :title, presence: true, length: { maximum: 100 }
  validates :email, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
CODE
  保存する前に値が正しいかを検査する。不正なデータがDBに入るのを防ぐ最後の砦。

  【重要】よく使う4つを覚えておけば大半は足りる。
    presence     → 空でないこと(必須項目)
    length       → 文字数の上限・下限
    uniqueness   → 重複していないこと
    numericality → 数値であること、範囲の指定

  検査に落ちると `save` は false を返し、理由が `errors.full_messages` に入る。
EXP

seed_snippet(model, "アソシエーション(1対多)", <<~CODE, <<~EXP)
  class User < ApplicationRecord
    has_many :posts, dependent: :destroy
  end

  class Post < ApplicationRecord
    belongs_to :user
  end
CODE
  テーブル同士の関係を定義する。これを書くと `user.posts` や `post.user` と書けるようになる。

  【重要】外部キー(user_id)を持つ側が belongs_to。
    has_many    → 「たくさん持っている」側(User)
    belongs_to  → 「所属している」側(Post。posts テーブルに user_id がある)

  `dependent: :destroy` は親を削除したとき子も一緒に消す指定。
  これが無いと、持ち主のいないデータがDBに残り続ける。
EXP

seed_snippet(model, "scope(よく使う条件に名前を付ける)", <<~CODE, <<~EXP)
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
CODE
  頻繁に使う検索条件に名前を付けて、使い回せるようにする。

  【重要】scopeは繋げて書ける。
    Post.published.recent
  条件が増えても読みやすく、`where(published: true).order(...)` を
  あちこちに書く必要がなくなる。

  引数も取れる。 scope :by_user, ->(user) { where(user: user) }
EXP

seed_snippet(model, "コールバック(保存の前後に処理)", <<~CODE, <<~EXP)
  before_save { self.email = email.downcase }
  before_validation :set_default_status
CODE
  保存やバリデーションの前後に、自動で実行される処理を仕込む。

  【重要】メールアドレスを小文字に統一する処理が典型例。
  「Test@example.com」と「test@example.com」を同じものとして扱うために必要。

  実行される順番: before_validation → バリデーション → before_save → 保存 → after_save

  【注意】コールバックを増やしすぎると、どこで値が変わったか追えなくなる。
  使うのは「必ず毎回実行したい処理」だけに留めるのが良い。
EXP

seed_snippet(model, "enum(状態を数値で管理)", <<~CODE, <<~EXP)
  enum status: { draft: 0, published: 1, archived: 2 }
CODE
  DBには数値で保存しつつ、コード上では意味のある名前で扱えるようにする。

  【重要】これを書くと便利なメソッドが自動生成される。
    post.draft?          → 下書きかどうか判定
    post.published!      → 公開状態に変更して保存
    Post.published       → 公開済みだけを取得

  DBに 0 や 1 で入るので容量が小さく、検索も速い。
  【注意】後から数字を振り直すと既存データの意味が変わるので、追加は末尾に行う。
EXP

# ============================================================
# ActiveRecordクエリ
# ============================================================

seed_snippet(ar, "where / find_by / find", <<~CODE, <<~EXP)
  User.where(active: true)
  User.find_by(email: "a@example.com")
  User.find(1)
CODE
  データを取り出す3つの基本。返ってくるものが違うので使い分ける。

  【重要】戻り値の違いが最も大事。
    where   → 複数件(該当0件でも空の配列が返る。エラーにならない)
    find_by → 1件だけ(該当なしは nil。存在チェックが必要)
    find    → 1件だけ(該当なしは例外発生 → 404ページになる)

  「必ず存在するはず」なら find、「無いかもしれない」なら find_by を使う。
EXP

seed_snippet(ar, "includes(N+1問題の解決)", <<~CODE, <<~EXP)
  posts = Post.includes(:user)
  posts.each { |post| puts post.user.name }
CODE
  関連するデータをまとめて先に読み込む。パフォーマンス改善で最重要のテクニック。

  【重要】includesが無いと何が起きるか。
    投稿100件を表示 → 投稿取得で1回 + 各投稿の著者取得で100回 = 計101回のSQL
  これがN+1問題。ページ表示が極端に遅くなる原因の第1位。

  includesを付ければ2回のSQLで済む。一覧画面で関連データを表示するときは必ず意識する。
EXP

seed_snippet(ar, "order / limit / offset", <<~CODE, <<~EXP)
  Post.order(created_at: :desc).limit(10)
CODE
  並び替えと件数の制限。「新着10件」のような表示で必ず使う組み合わせ。

  【重要】order の向きを表す2つ。
    :desc → 降順(新しい順、大きい順)
    :asc  → 昇順(古い順、小さい順)

  limitを付けずに全件取得すると、データが増えたときにメモリを圧迫する。
  一覧表示では必ずlimitかページネーション(kaminari等)を使う。
EXP

seed_snippet(ar, "update と destroy", <<~CODE, <<~EXP)
  post.update(title: "新しいタイトル")
  post.destroy
CODE
  レコードの更新と削除。

  【重要】末尾に ! が付くかどうかで挙動が変わる。
    update   → 失敗すると false を返す(処理は続く)
    update!  → 失敗すると例外が発生する(処理が止まる)

  コントローラでは if文で分岐したいので `update`、
  seedやバッチ処理では失敗に気付きたいので `update!` を使うことが多い。
EXP

seed_snippet(ar, "pluck(特定カラムだけ取得)", <<~CODE, <<~EXP)
  User.pluck(:email)
  User.where(active: true).pluck(:id, :name)
CODE
  必要なカラムの値だけを配列で取り出す。

  【重要】`User.all.map(&:email)` との違いを理解すると効果的。
    map   → 全カラムを読み込みモデルを生成してから、値を取り出す(重い)
    pluck → 必要なカラムだけSQLで取得する(軽い)

  IDの一覧が欲しいだけ、メールアドレスだけ欲しい、という場面では pluck が圧倒的に速い。
EXP

seed_snippet(ar, "exists? と count", <<~CODE, <<~EXP)
  User.exists?(email: "a@example.com")
  Post.where(published: true).count
CODE
  存在確認と件数の集計。

  【重要】存在確認に count を使わないこと。
    悪い例: Post.where(user: user).count > 0
    良い例: Post.where(user: user).exists?

  countは全件を数えるが、exists?は1件見つかった時点で処理を止める。
  データ量が多いほど差が大きくなる。
EXP

seed_snippet(ar, "joins(テーブルの結合)", <<~CODE, <<~EXP)
  Post.joins(:user).where(users: { active: true })
CODE
  関連テーブルを結合して、そちらの条件で絞り込む。

  【重要】includes との使い分けが頻出ポイント。
    joins    → 絞り込みたいだけ(関連データは表示しない)
    includes → 関連データを画面に表示する(N+1対策)

  where の中ではテーブル名を複数形で書く点に注意(user ではなく users)。
EXP

# ============================================================
# マイグレーション
# ============================================================

seed_snippet(migrate, "テーブルの作成", <<~CODE, <<~EXP)
  create_table :posts do |t|
    t.string :title, null: false
    t.text :body
    t.references :user, foreign_key: true
    t.timestamps
  end
CODE
  テーブルを新規作成する。マイグレーションの基本形。

  【重要】覚えておきたい型と指定。
    string     → 短い文字列(255文字まで。タイトルや名前)
    text       → 長い文字列(本文やコメント)
    references → 外部キー(自動で user_id カラムとインデックスが作られる)
    timestamps → created_at と updated_at を自動生成

  `null: false` はDB側で空を禁止する指定。モデルのvalidatesと併用すると確実。
EXP

seed_snippet(migrate, "カラムの追加と削除", <<~CODE, <<~EXP)
  add_column :posts, :published, :boolean, default: false
  remove_column :posts, :old_field, :string
CODE
  既存テーブルにカラムを追加・削除する。

  【重要】既にデータがあるテーブルに `null: false` のカラムを足すとエラーになる。
  既存レコードの値が空になってしまうため。必ず `default:` を一緒に指定する。

  remove_column で型(:string)を書くのは、rollbackで元に戻せるようにするため。
  省略すると取り消しができなくなる。
EXP

seed_snippet(migrate, "インデックスの追加", <<~CODE, <<~EXP)
  add_index :users, :email, unique: true
CODE
  検索を高速化する仕組み。本の索引と同じ役割。

  【重要】付けるべき場所は2つ。
    ・検索条件によく使うカラム(where で頻繁に指定するもの)
    ・重複を禁止したいカラム(unique: true)

  uniqueインデックスはDB側で重複を防ぐ。
  モデルの `validates :email, uniqueness: true` だけでは、
  同時アクセス時に重複が入り込む可能性があるため、両方書くのが安全。
EXP

seed_snippet(migrate, "マイグレーションの実行と取り消し", <<~CODE, <<~EXP)
  rails db:migrate
  rails db:rollback
  rails db:migrate:status
CODE
  マイグレーションの操作コマンド3種。

  【重要】使い分け。
    db:migrate         → 未実行のマイグレーションを全て実行
    db:rollback        → 直前の1つを取り消す(STEP=2 で2つ戻せる)
    db:migrate:status  → どれが実行済みか一覧で確認

  【注意】既にチームに共有(push)したマイグレーションは rollback して書き換えない。
  他の人のDBと状態がずれる。修正したいときは新しいマイグレーションを追加する。
EXP

# ============================================================
# ビュー・フォーム
# ============================================================

seed_snippet(view, "form_with(フォームの基本)", <<~CODE, <<~EXP)
  <%= form_with model: @post do |f| %>
    <%= f.text_field :title, class: "form-control" %>
    <%= f.submit "保存する" %>
  <% end %>
CODE
  Rails標準のフォーム。HTMLで書くよりも安全で短い。

  【重要】@postの状態で送信先が自動で切り替わる。
    新規(Post.new)     → POST  /posts    (createへ)
    既存(保存済み)      → PATCH /posts/1  (updateへ)

  新規用と編集用でフォームを分ける必要がなく、同じ部分テンプレートを使い回せる。
  CSRF対策のトークンも自動で埋め込まれる。
EXP

seed_snippet(view, "link_to(リンクの生成)", <<~CODE, <<~EXP)
  <%= link_to "詳細", post_path(post) %>
  <%= link_to "削除", post_path(post), data: { turbo_method: :delete } %>
CODE
  リンクを作るヘルパー。URLを直接書かずパスヘルパーを使うのが鉄則。

  【重要】`"/posts/1"` と直書きしないこと。
  URL構造を変えたときに全ての箇所を直す必要が出てしまう。
  `post_path(post)` ならルーティングの変更に自動で追従する。

  削除リンクには turbo_method の指定が必要(Rails 7以降)。
  これが無いとGETリクエストになり、削除が実行されない。
EXP

seed_snippet(view, "部分テンプレート(render partial)", <<~CODE, <<~EXP)
  <%= render "form", post: @post %>
  <%= render partial: "post", collection: @posts %>
CODE
  繰り返し使う画面部品を切り出して共通化する。ファイル名は先頭に _ を付ける(_form.html.erb)。

  【重要】collection を使うと each を書かずに一覧を描画できる。
  上の2行目は、@postsの件数分だけ _post.html.erb を描画する。
  内部で最適化されるため、eachで回すより速い。

  新規作成画面と編集画面でフォームを共通化するのが最も多い使い道。
EXP

seed_snippet(view, "条件分岐と繰り返し(ERB)", <<~CODE, <<~EXP)
  <% if @posts.any? %>
    <% @posts.each do |post| %>
      <p><%= post.title %></p>
    <% end %>
  <% end %>
CODE
  ビューの中でRubyを書くための記法。

  【重要】2種類のタグの違いが最重要。
    <%= %> → 結果を画面に出力する(値を表示したいとき)
    <%  %> → 実行するだけ(if や each など制御構文)

  eachやifに <%= %> を使うと余計な文字が画面に出る。
  逆に値の表示で <% %> を使うと何も表示されない。初心者が最も間違えるポイント。
EXP

seed_snippet(view, "よく使うヘルパー", <<~CODE, <<~EXP)
  <%= number_with_delimiter(1234567) %>
  <%= l Time.current, format: :short %>
  <%= truncate(post.body, length: 100) %>
CODE
  表示を整えるための便利メソッド。

  【重要】それぞれの役割。
    number_with_delimiter → 1234567 を 1,234,567 に(3桁区切り)
    l (localize)          → 日時を日本語形式に(config/locales の設定に従う)
    truncate              → 長い文章を指定文字数で切って「...」を付ける

  自分で整形処理を書く前に、Railsに用意されていないか探す習慣をつけると良い。
EXP

# ============================================================
# 認証・セキュリティ
# ============================================================

seed_snippet(auth, "has_secure_password", <<~CODE, <<~EXP)
  class User < ApplicationRecord
    has_secure_password
  end
CODE
  これ1行でパスワード認証の仕組みが手に入る。bcrypt gemが必要。

  【重要】パスワードは絶対にそのまま保存してはいけない。
  この機能はパスワードをハッシュ化(復元できない形に変換)して
  `password_digest` カラムに保存する。DBが漏洩しても元のパスワードは分からない。

  自動で使えるようになるもの:
    user.password = "..."        → 代入すると自動でハッシュ化
    user.authenticate("...")     → 正しければユーザー、違えば false
EXP

seed_snippet(auth, "セッション(ログイン状態の保持)", <<~CODE, <<~EXP)
  session[:user_id] = user.id
  session[:user_id] = nil
CODE
  ログイン状態をブラウザとサーバー間で保持する仕組み。

  【重要】sessionに入れるのは「IDだけ」にする。
  ユーザー情報そのものを入れると、情報が更新されても古いまま残ってしまう。
  IDだけ保存し、必要なときにDBから取り直すのが正しい形。

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

  ログアウトは nil を代入するだけ。
EXP

seed_snippet(auth, "ログイン必須にする", <<~CODE, <<~EXP)
  before_action :require_login

  private

  def require_login
    return if current_user
    redirect_to login_path, alert: "ログインしてください"
  end
CODE
  未ログインのユーザーを弾く仕組み。

  【重要】画面にリンクを表示しないだけでは不十分。
  URLを直接入力すればアクセスできてしまうため、
  サーバー側(コントローラ)で必ずチェックする必要がある。

  ApplicationControllerに書けば全コントローラに適用され、
  ログイン画面など一部だけ `skip_before_action :require_login` で除外できる。
EXP

seed_snippet(auth, "本人だけが操作できるようにする", <<~CODE, <<~EXP)
  def set_own_post
    @post = current_user.posts.find(params[:id])
  end
CODE
  他人のデータを勝手に編集・削除されないようにする書き方。

  【重要】`Post.find(params[:id])` との違いが決定的。
    Post.find(...)               → 誰の投稿でも取得できてしまう(危険)
    current_user.posts.find(...) → 自分の投稿しか取得できない

  他人のIDを指定された場合は例外が発生し、404ページになる。
  URLのIDを書き換えるだけで他人のデータを操作できてしまう事故を防げる。
EXP

# ============================================================
# テスト(RSpec)
# ============================================================

seed_snippet(spec, "テストの基本構造", <<~CODE, <<~EXP)
  RSpec.describe User, type: :model do
    it "名前が無ければ無効" do
      user = User.new(name: nil)
      expect(user).to be_invalid
    end
  end
CODE
  RSpecの最小構成。3つのキーワードで成り立っている。

  【重要】それぞれの役割。
    describe → 何をテストするかのまとまり
    it       → 1つのテストケース(「〜であること」を日本語で書くと読みやすい)
    expect   → 実際の検証(expect(実際の値).to 期待する状態)

  テスト名は後から読む人のための説明書になる。
  「〜が正しいこと」ではなく「名前が無ければ無効」のように具体的に書く。
EXP

seed_snippet(spec, "よく使うマッチャ", <<~CODE, <<~EXP)
  expect(user.name).to eq "太郎"
  expect(user).to be_valid
  expect { user.save }.to change(User, :count).by(1)
CODE
  expectの後に続く「期待する状態」の書き方。

  【重要】用途別の3種類。
    eq        → 値が等しいか
    be_valid  → バリデーションを通るか(be_ + メソッド名で ○○? を検査)
    change    → 処理の前後で数が変化したか

  3行目は「saveを実行したらUserの件数が1増える」という意味。
  ブロック { } で囲む点に注意。
EXP

seed_snippet(spec, "let と before", <<~CODE, <<~EXP)
  let(:user) { User.create!(name: "太郎") }

  before do
    login_as(user)
  end
CODE
  テストの準備を共通化する2つの方法。

  【重要】使い分けが大事。
    let    → 呼ばれたときに初めて実行される(使わないテストでは動かない = 速い)
    before → 各テストの前に必ず実行される(ログイン処理など毎回必要なもの)

  データの準備は基本 let、副作用のある準備は before と覚えておくと良い。
EXP

seed_snippet(spec, "リクエストスペック", <<~CODE, <<~EXP)
  it "一覧が表示される" do
    get posts_path
    expect(response).to have_http_status(:ok)
  end
CODE
  実際にURLへアクセスして、正しく応答が返るか確認するテスト。

  【重要】モデルのテストより優先度が高いことが多い。
  画面が表示できるかを確かめるので、ルーティング・コントローラ・ビューを
  まとめて検証でき、壊れたときに気付きやすい。

    have_http_status(:ok)       → 200番(正常表示)
    have_http_status(:redirect) → 300番台(リダイレクト)
EXP

# ============================================================
# コマンド・設定
# ============================================================

seed_snippet(cfg, "generate(ファイルの自動生成)", <<~CODE, <<~EXP)
  rails g model Post title:string body:text
  rails g controller Posts index show
  rails g migration AddPublishedToPosts published:boolean
CODE
  必要なファイルを自動生成するコマンド。`g` は `generate` の省略形。

  【重要】マイグレーション名には規則があり、それに従うと中身も自動で書かれる。
    AddXxxToTable    → カラム追加のコードが生成される
    RemoveXxxFromTable → カラム削除のコードが生成される

  間違えて生成したときは `rails destroy` で取り消せる(g を destroy に変えるだけ)。
EXP

seed_snippet(cfg, "データベース関連コマンド", <<~CODE, <<~EXP)
  rails db:create
  rails db:migrate
  rails db:seed
CODE
  開発を始めるときの3点セット。この順番で実行する。

  【重要】それぞれの役割。
    db:create  → データベース自体を作る(最初の1回だけ)
    db:migrate → テーブルを作る・変更する
    db:seed    → 初期データを流し込む(db/seeds.rb を実行)

  やり直したいときは `rails db:reset`(削除して作り直し + seed)が便利。
  【注意】db:reset は本番環境では絶対に実行しないこと。全データが消える。
EXP

seed_snippet(cfg, "確認・デバッグ用コマンド", <<~CODE, <<~EXP)
  rails routes
  rails console
  rails server
CODE
  開発中に最も使う3つ。省略形は順に無し、`rails c`、`rails s`。

  【重要】使いどころ。
    routes  → 「このURLはどのアクションに繋がる?」を確認
    console → モデルを直接触って動作確認(データの中身を見る、クエリを試す)
    server  → 開発用サーバーの起動

  consoleで `Post.count` などを試すと、コードを書く前に動作を確認できる。
  `rails c --sandbox` にすると、終了時に変更が取り消されるので安全に試せる。
EXP

seed_snippet(cfg, "Gemの追加", <<~CODE, <<~EXP)
  # Gemfile に追記
  gem "kaminari"

  # ターミナルで実行
  bundle install
CODE
  外部ライブラリ(gem)を導入する手順。

  【重要】`bundle install` を実行すると Gemfile.lock が更新される。
  このファイルには実際にインストールされたバージョンが記録され、
  チーム全員・本番環境で同じバージョンが使われることが保証される。

  Gemfile.lock は必ずGitにコミットする。これを共有しないと
  「自分の環境では動くのに他の人の環境では動かない」原因になる。
EXP

# ============================================================
# HTML
# ============================================================

seed_snippet(html, "HTMLの基本構造", <<~CODE, <<~EXP, "html")
  <!DOCTYPE html>
  <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <title>ページタイトル</title>
    </head>
    <body>
    </body>
  </html>
CODE
  すべてのHTMLファイルの土台となる形。

  【重要】各行の役割。
    <!DOCTYPE html> → HTML5で書くという宣言(1行目に必須)
    lang="ja"       → 日本語のページだと伝える(読み上げソフトや翻訳が正しく動く)
    charset="UTF-8" → 文字コードの指定(これが無いと日本語が文字化けする)

  head は画面に表示されない情報、body は実際に表示される内容を書く。
EXP

seed_snippet(html, "見出しと段落", <<~CODE, <<~EXP, "html")
  <h1>大見出し</h1>
  <h2>中見出し</h2>
  <p>これは段落のテキストです。</p>
CODE
  文章の構造を表すタグ。

  【重要】h1 は1ページに1つだけにする。
  見出しは h1 → h2 → h3 と順番に使い、飛ばさないのが原則。
  検索エンジンや読み上げソフトが、この階層でページ構造を理解している。

  「文字を大きくしたいから h1」という使い方は間違い。
  見た目はCSSで調整し、タグは意味で選ぶ。
EXP

seed_snippet(html, "リンクと画像", <<~CODE, <<~EXP, "html")
  <a href="https://example.com">リンクテキスト</a>
  <img src="/images/photo.jpg" alt="写真の説明">
CODE
  Webページの根幹となる2つのタグ。

  【重要】alt属性は省略しない。
  画像が読み込めなかったときに代わりに表示され、
  目の見えない人が使う読み上げソフトはこの文章を読み上げる。

  別タブで開きたいときは target="_blank" を付けるが、
  セキュリティ上 rel="noopener" も一緒に付けるのが推奨される。
EXP

seed_snippet(html, "リスト", <<~CODE, <<~EXP, "html")
  <ul>
    <li>箇条書きの項目</li>
    <li>2つ目の項目</li>
  </ul>
CODE
  箇条書きを作るタグ。

  【重要】2種類の使い分け。
    <ul> → 順序が関係ないリスト(メニュー、特徴の列挙など)
    <ol> → 順序に意味があるリスト(手順、ランキングなど。番号が自動で付く)

  どちらも中身は必ず <li> で囲む。li 以外を直接入れてはいけない。
  ナビゲーションメニューは ul で作るのが一般的。
EXP

seed_snippet(html, "フォーム", <<~CODE, <<~EXP, "html")
  <form action="/posts" method="post">
    <label for="title">タイトル</label>
    <input type="text" id="title" name="title">
    <button type="submit">送信</button>
  </form>
CODE
  ユーザーからの入力を受け取る仕組み。

  【重要】name属性が最も大事。
  サーバー側はこの name をキーにして値を受け取る(Railsなら params[:title])。
  name が無いと、入力しても値が送信されない。

  label の for と input の id を一致させると、
  ラベルをクリックしただけで入力欄が選択される。使いやすさが大きく変わる。
EXP

seed_snippet(html, "input の種類", <<~CODE, <<~EXP, "html")
  <input type="email" name="email" required>
  <input type="password" name="password">
  <input type="number" name="age" min="0">
CODE
  入力欄の型を指定すると、ブラウザが自動で検証や最適化をしてくれる。

  【重要】type を適切に選ぶ利点。
    email    → 形式が正しいかブラウザが自動チェック
    password → 入力内容が「●●●」で隠れる
    number   → スマホで数字キーボードが開く

  required を付けると、空のまま送信しようとした時点でブラウザが止めてくれる。
  【注意】ブラウザ側の検証は回避できるので、サーバー側の検証も必ず行う。
EXP

seed_snippet(html, "div と span", <<~CODE, <<~EXP, "html")
  <div class="card">
    <span class="badge">新着</span>
  </div>
CODE
  意味を持たない、まとめるためだけのタグ。

  【重要】2つの違いは配置のされ方。
    div  → ブロック要素(前後で改行され、縦に積まれる)
    span → インライン要素(文章の途中に置ける。改行されない)

  レイアウトの箱を作るなら div、文章中の一部だけ装飾するなら span。

  【注意】何でも div にするのは避ける。見出しなら h2、
  ナビゲーションなら nav のように、意味のあるタグを優先する。
EXP

seed_snippet(html, "テーブル(表)", <<~CODE, <<~EXP, "html")
  <table>
    <thead>
      <tr><th>名前</th><th>年齢</th></tr>
    </thead>
    <tbody>
      <tr><td>太郎</td><td>20</td></tr>
    </tbody>
  </table>
CODE
  表形式のデータを表示する。

  【重要】タグの対応関係。
    tr → 横1行(table row)
    th → 見出しセル(table header。太字で中央寄せになる)
    td → データセル(table data)

  thead(見出し部分)と tbody(データ部分)で分けると構造が明確になる。

  【注意】表はデータを見せるためのもの。レイアウト目的で使ってはいけない。
EXP

# ============================================================
# 番外編: 環境構築
# ============================================================

seed_snippet(setup, "アプリを新規作成する", <<~CODE, <<~EXP)
  rails new myapp --database=postgresql
  cd myapp
  rails db:create
CODE
  Railsアプリを一から作るときの最初の3手。

  【重要】`--database` は後から変えると手間がかかるので、最初に決める。
    postgresql → 本番運用の定番。Render・Heroku等がそのまま対応している
    mysql      → 既存システムとの連携が必要な場合
    sqlite3    → 指定しない場合のデフォルト。手軽だが本番には向かない

  【注意】既存フォルダに作る場合は `rails new .` とする。
  その際 Gemfile などを上書きするか聞かれるので、必要なファイルは退避しておく。
EXP

seed_snippet(setup, "Dockerfile(開発環境の土台)", <<~CODE, <<~EXP)
  FROM ruby:3.2.3

  WORKDIR /myapp

  COPY Gemfile* ./
  RUN bundle install

  COPY . .

  CMD ["rails", "server", "-b", "0.0.0.0"]
CODE
  同じ開発環境をチーム全員・本番で再現するための設計図。

  【重要】Gemfileだけ先にCOPYしてからbundle installする理由。
  Dockerは行ごとに結果をキャッシュする。先に全ファイルをコピーすると、
  コードを1文字直しただけで bundle install がやり直しになる。
  Gemfileを先に置けば、gemを変えない限りインストールは再利用される。

  【注意】`-b "0.0.0.0"` は必須。これが無いとコンテナの外から接続できない。
EXP

seed_snippet(setup, "compose.yml(複数コンテナの連携)", <<~CODE, <<~EXP)
  services:
    db:
      image: postgres:16
      environment:
        POSTGRES_PASSWORD: password
      volumes:
        - postgres_data:/var/lib/postgresql/data
    web:
      build: .
      ports:
        - "3000:3000"
      depends_on:
        - db

  volumes:
    postgres_data:
CODE
  アプリ用とDB用のコンテナをまとめて起動する設定。

  【重要】volumes の指定が最も大事。
  コンテナは削除すると中のデータも消える。volumesで外部に保存領域を作っておけば、
  コンテナを作り直してもDBの中身は残る。これが無いと再起動のたびに全データが消える。

  【重要】ports は「パソコン側:コンテナ側」の順。
  `"3001:3000"` ならブラウザでは localhost:3001 でアクセスする。
EXP

seed_snippet(setup, "database.yml(DB接続設定)", <<~CODE, <<~EXP)
  default: &default
    adapter: postgresql
    encoding: unicode
    username: <%= ENV.fetch("DATABASE_USERNAME") { "postgres" } %>
    password: <%= ENV.fetch("DATABASE_PASSWORD") { "password" } %>
    host: <%= ENV.fetch("DATABASE_HOST") { "db" } %>
CODE
  アプリがどのデータベースに繋ぐかを決めるファイル。

  【重要】host には「db」のようなサービス名を書く。
  Docker Composeでは、compose.ymlに書いたサービス名がそのままホスト名になる。
  localhost と書くと「自分自身のコンテナ」を指してしまい接続できない。

  【重要】パスワードは直書きせず ENV.fetch で環境変数から読む。
  第2引数は環境変数が無いときの初期値。これで開発と本番の設定を1つのファイルで両立できる。
EXP

seed_snippet(setup, "コンテナの起動とDB準備", <<~CODE, <<~EXP)
  docker compose build
  docker compose up -d
  docker compose exec web bundle exec rails db:create db:migrate db:seed
CODE
  環境構築後、アプリが動くまでの一連の流れ。

  【重要】それぞれの役割。
    build → Dockerfileからイメージ(環境の型)を作る
    up -d → コンテナを起動(-d はバックグラウンド実行)
    exec  → 起動中のコンテナの中でコマンドを実行

  DB関連のコマンドはコンテナの中で動かす必要があるため `exec web` を付ける。
  【注意】Gemfileを変更したら build からやり直さないと反映されない。
EXP

seed_snippet(setup, "困ったときの確認コマンド", <<~CODE, <<~EXP)
  docker compose ps
  docker compose logs web --tail 50
  docker compose down
CODE
  コンテナが起動しない・アプリが表示されないときの調査手順。

  【重要】使う順番。
    ps    → コンテナが起動しているか確認(Up か Exited か)
    logs  → エラーメッセージを読む。原因はほぼここに書いてある
    down  → 全コンテナを停止して削除(やり直したいとき)

  【注意】`down -v` はvolumesも削除するのでDBのデータが全部消える。
  普段は -v を付けない。付けるのは「最初から作り直したい」と決めたときだけ。
EXP

seed_snippet(setup, "ポート衝突の対処", <<~CODE, <<~EXP)
  lsof -i :3000
  docker ps
CODE
  「port is already allocated」エラーが出たときの調べ方。

  【重要】原因は「別のアプリが同じポートを使っている」こと。
  Railsは3000番、PostgreSQLは5432番を使うため、
  複数のプロジェクトを同時に動かすとぶつかりやすい。

  解決策は2つ。
    ・使っている方を止める(docker compose down)
    ・compose.yml のポートをずらす("3001:3000" のように左側を変える)

  変えるのは左側(パソコン側)だけ。右側を変えるとアプリに繋がらなくなる。
EXP

# ============================================================
# 番外編: デプロイ
# ============================================================

seed_snippet(deploy, "本番で必要な環境変数", <<~CODE, <<~EXP)
  RAILS_ENV=production
  RAILS_MASTER_KEY=xxxxxxxx
  RAILS_SERVE_STATIC_FILES=true
  DATABASE_URL=postgresql://user:pass@host/dbname
CODE
  デプロイ先(Render等)の管理画面で設定する値。1つでも欠けると動かない。

  【重要】それぞれの役割。
    RAILS_MASTER_KEY         → config/master.key の中身。暗号化された設定を復号する鍵
    RAILS_SERVE_STATIC_FILES → CSSや画像をRails自身が配信する指定。無いと画面が真っ白になる
    DATABASE_URL             → 接続先DB。これがあれば database.yml の設定より優先される

  【注意】master.key は絶対にGitにコミットしない(.gitignoreに入っている)。
  漏れると暗号化した情報が全て読まれてしまう。管理画面から手入力で登録する。
EXP

seed_snippet(deploy, "アセットのプリコンパイル", <<~CODE, <<~EXP)
  bundle exec rails assets:precompile
CODE
  CSSやJavaScriptを本番用にまとめる処理。デプロイで最もつまずくポイント。

  【重要】これを忘れると起動後に必ずエラーになる。
    ActionView::Template::Error
    The asset "application.css" is not present in the asset pipeline

  開発環境ではアクセスのたびに自動で組み立ててくれるが、
  本番は速度のため事前に1回だけ作る方式に変わる。だから明示的な実行が必要。

  【注意】ビルド時にDBへ繋がないので、ダミーの DATABASE_URL と
  SECRET_KEY_BASE を渡さないと失敗することがある。
EXP

seed_snippet(deploy, "ビルドスクリプト", <<~CODE, <<~EXP)
  #!/usr/bin/env bash
  set -o errexit

  bundle install
  yarn install
  bundle exec rails assets:precompile
  bundle exec rails db:migrate
CODE
  デプロイ時に実行される手順をまとめたファイル(bin/render-build.sh など)。

  【重要】1行目の set -o errexit を必ず書く。
  これが無いと途中でエラーが起きても最後まで実行され、
  「ビルドは成功したのにアプリが壊れている」という分かりにくい状態になる。

  【注意】ファイルに実行権限が必要。付け忘れると Permission denied で失敗する。
    chmod +x bin/render-build.sh
    git update-index --chmod=+x bin/render-build.sh
EXP

seed_snippet(deploy, "本番のマイグレーション", <<~CODE, <<~EXP)
  bundle exec rails db:migrate
CODE
  本番DBにテーブルを作る・変更する処理。デプロイのたびに実行する。

  【重要】忘れると次のエラーが出る。
    PG::UndefinedTable: ERROR: relation "users" does not exist

  「テーブルが存在しない」という意味。マイグレーションが一度も
  実行されていない状態を示す典型的なメッセージ。

  【注意】本番では db:reset や db:drop を絶対に実行しない。全ユーザーのデータが消える。
  やり直したいときも、必ず新しいマイグレーションを追加する形で対応する。
EXP

seed_snippet(deploy, "デプロイ設定はどこが使われるか", <<~CODE, <<~EXP)
  # Dockerタイプ  → Dockerfile の内容が使われる
  # ネイティブ環境 → buildCommand の内容が使われる
CODE
  同じサービスでも、作成時に選んだタイプで読まれる設定ファイルが変わる。

  【重要】ここを取り違えると、直しても直しても反映されない。
  ビルドログの最初の数行で見分けられる。

    load build definition from Dockerfile   → Dockerタイプ
    Running build command './bin/...'       → ネイティブ環境

  Dockerタイプの場合、buildCommandや管理画面のビルド設定は完全に無視される。
  必要な処理はDockerfileの中に書く必要がある。
EXP

seed_snippet(deploy, "ログの読み分け", <<~CODE, <<~EXP)
  # Build log   … なぜ壊れたか(原因)
  # Runtime log … 何が壊れたか(症状)
CODE
  デプロイで問題が起きたとき、見るべきログは2種類ある。

  【重要】症状だけ見て推測すると遠回りになる。
    Runtime log の「application.css が無い」は症状。
    Build log を見ると「そもそもCSSを作る処理が走っていない」と原因が分かる。

  見分け方は先頭の行。
    Cloning from ... で始まる → Build log
    Started GET "/" がある     → Runtime log

  まず症状を掴み、次に必ずBuild logで原因を確かめる、という順番が近道。
EXP

seed_snippet(deploy, "無料プランのスリープ", <<~CODE, <<~EXP)
  # 15分アクセスが無いとサーバーが停止する
  # 次のアクセス時に起動し直すため50秒ほどかかる
CODE
  無料プランで「表示が異常に遅い」と感じたときの主な原因。

  【重要】これはコードの最適化では解決できない。
  起動後は0.3秒で表示されるのに初回だけ遅い場合、ほぼこれが原因。

  対処は2つ。
    ・有料プランにする(スリープしなくなる)
    ・外部サービスから定期的にアクセスして起こし続ける

  【注意】画像やCSSの軽量化は別問題として有効。
  2.7MBの画像を545KBに圧縮するだけで、起動後の表示は確実に速くなる。
EXP

# カテゴリ名を再編したことで空になった旧カテゴリを片付ける。
# ユーザーが追加したコードが1件でも残っているカテゴリは削除しない。
Category.left_joins(:snippets).where(snippets: { id: nil }).destroy_all

puts "Seed完了: カテゴリ#{Category.count}件 / 公式スニペット#{Snippet.official.count}件"
