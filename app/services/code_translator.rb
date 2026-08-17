# 貼り付けられたコードを日本語に訳す。
#
# 外部サービスに頼らず、辞書とパターンで解析している。
# 完璧な翻訳はできないが、「この行が何をしているか」を掴む助けにはなる。
# 判断できなかった行はその旨を返し、分かったふりをしないようにしている。
class CodeTranslator
  # ------------------------------------------------------------
  # 単語辞書。コード中に現れた語だけを拾って表示する。
  # ------------------------------------------------------------
  DICTIONARY = {
    # Ruby の基本
    "class" => "クラス。設計図にあたるまとまり(HTMLでは見た目を指定する名前)",
    "module" => "module。まとめて名前を付けた部品",
    "def" => "define の略。処理を定義する",
    "end" => "終わり。まとまりの閉じ",
    "if" => "もし〜なら",
    "elsif" => "そうでなくて、もし〜なら",
    "else" => "そうでなければ",
    "unless" => "〜でなければ",
    "return" => "戻る・値を返す",
    "nil" => "何もない状態",
    "true" => "真・はい",
    "false" => "偽・いいえ",
    "self" => "自分自身",
    "private" => "非公開。外から呼べない",
    "public" => "公開",
    "protected" => "限定公開",
    "require" => "必要とする・読み込む",
    "puts" => "出力する(put string の略)",
    "each" => "それぞれ。順に取り出す",
    "map" => "写像。各要素を変換する",
    "select" => "選ぶ。条件に合うものだけ残す",
    "reject" => "除く",
    "attr_accessor" => "属性への読み書きを用意する",
    "do" => "〜する(まとまりの始まり)",
    "then" => "そのとき",
    "yield" => "譲る。渡されたまとまりを実行する(ビューでは中身を差し込む場所)",

    # Rails モデル
    "ApplicationRecord" => "Railsのモデルの土台",
    "validates" => "検証する。保存前の入力チェック",
    "presence" => "存在すること(必須)",
    "uniqueness" => "一意であること(重複しない)",
    "numericality" => "数値であること",
    "length" => "長さ",
    "maximum" => "最大",
    "minimum" => "最小",
    "format" => "書式",
    "inclusion" => "含まれること",
    "has_many" => "多数を持つ",
    "has_one" => "1つを持つ",
    "belongs_to" => "〜に属する",
    "dependent" => "依存した。親と運命を共にする指定",
    "optional" => "任意の。無くてもよい",
    "through" => "〜を経由して",
    "scope" => "範囲。よく使う絞り込みの名前",
    "enum" => "列挙。選択肢に名前を付ける",
    "default" => "初期値",
    "has_secure_password" => "パスワードを安全に扱う仕組み",
    "before_save" => "保存の前に",
    "after_save" => "保存の後に",
    "before_validation" => "検証の前に",
    "before_create" => "作成の前に",
    "before_destroy" => "削除の前に",

    # Rails コントローラ
    "ApplicationController" => "Railsのコントローラの土台",
    "before_action" => "処理の前に実行する",
    "skip_before_action" => "前処理を飛ばす",
    "params" => "parameters の略。送られてきた値",
    "permit" => "許可する",
    "session" => "接続状態の記憶。ログイン維持などに使う",
    "cookies" => "ブラウザに保存する小さなデータ",
    "redirect_to" => "別の場所へ転送する",
    "render" => "描画する・表示する",
    "notice" => "お知らせ(良い報告)",
    "alert" => "警告",
    "flash" => "一度だけ表示するメッセージ",
    "status" => "状態。通信結果の番号",
    "respond_to" => "形式ごとに応答を切り替える",
    "head" => "頭。HTMLでは表示されない情報の置き場",
    "only" => "〜だけ",
    "except" => "〜以外",

    # Rails クエリ
    "where" => "〜という条件で",
    "find" => "見つける(無ければエラー)",
    "find_by" => "〜によって見つける(無ければnil)",
    "find_each" => "少しずつ取り出して繰り返す",
    "order" => "並べる",
    "limit" => "件数の上限",
    "offset" => "何件目から取るか",
    "includes" => "関連も一緒に読み込む(N+1対策)",
    "joins" => "テーブルを結合する",
    "pluck" => "摘み取る。指定の列だけ取り出す",
    "count" => "数える",
    "sum" => "合計する",
    "average" => "平均する",
    "exists?" => "存在するか?",
    "group" => "グループにまとめる",
    "distinct" => "重複を除く",
    "all" => "すべて",
    "first" => "最初の1件",
    "last" => "最後の1件",
    "new" => "新しく作る(未保存)",
    "create" => "作成して保存する",
    "save" => "保存する",
    "update" => "更新する",
    "destroy" => "削除する",
    "desc" => "降順(新しい順・大きい順)",
    "asc" => "昇順(古い順・小さい順)",
    "active" => "有効な",

    # ルーティング
    "resources" => "資源。7つの経路を一括で作る",
    "resource" => "単数の資源(一覧を持たない)",
    "root" => "サイトの入口(トップページ)",
    "namespace" => "名前空間。区切られた領域",
    "member" => "個別の1件に対する経路",
    "collection" => "一覧全体に対する経路",
    "get" => "取得する(ページを見る)",
    "post" => "送信する(新規作成)",
    "patch" => "一部を更新する",
    "put" => "まるごと更新する",
    "delete" => "削除する",
    "to" => "〜へ",
    "as" => "〜という名前で",

    # マイグレーション
    "create_table" => "表を作る",
    "drop_table" => "表を削除する",
    "add_column" => "列を追加する",
    "remove_column" => "列を削除する",
    "rename_column" => "列の名前を変える",
    "add_index" => "索引を追加する",
    "add_reference" => "他の表への参照を追加する",
    "references" => "参照。他の表とのつながり",
    "foreign_key" => "外部キー。他の表を指す印",
    "timestamps" => "作成日時と更新日時",
    "string" => "短い文字列",
    "text" => "長い文章",
    "integer" => "整数",
    "boolean" => "真偽値(はい・いいえ)",
    "datetime" => "日時",
    "float" => "小数",
    "decimal" => "小数(誤差の出ない形式)",
    "null" => "空・値なし",
    "unique" => "唯一の。重複しない",
    "change" => "変更する",
    "migration" => "移行。DB構造の変更",

    # ビュー
    "form_with" => "フォームを作る",
    "link_to" => "リンクを作る",
    "button_to" => "ボタン形式のリンクを作る",
    "image_tag" => "画像を表示する",
    "text_field" => "1行の入力欄",
    "text_area" => "複数行の入力欄",
    "submit" => "送信する",
    "label" => "名札",
    "partial" => "部分的な。切り出した部品",
    "content_for" => "名前を付けて中身を預ける",

    # テスト
    "describe" => "記述する。何について調べるか",
    "context" => "文脈。条件の区切り",
    "it" => "それ。1つの検証項目",
    "expect" => "期待する",
    "eq" => "equal の略。等しい",
    "let" => "〜とする。必要時に用意する",
    "before" => "前に",
    "after" => "後に",
    "subject" => "主題。検証の対象",
    "valid?" => "有効か?",
    "invalid?" => "無効か?",

    # HTML
    "html" => "HTML文書全体",
    "body" => "体。表示される中身",
    "div" => "division の略。区画",
    "span" => "範囲。文中の小さなまとまり",
    "form" => "入力用紙",
    "input" => "入力欄",
    "button" => "ボタン",
    "table" => "表",
    "thead" => "表の見出し部分",
    "tbody" => "表のデータ部分",
    "img" => "image の略。画像",
    "src" => "source の略。読み込み元",
    "href" => "参照先のURL",
    "alt" => "画像が出ないときの代わりの説明",
    "id" => "識別子。1つだけの目印",
    "name" => "名前。送信時の鍵になる",
    "type" => "種類",
    "value" => "値",
    "placeholder" => "入力前に薄く出る例文",
    "required" => "必須の"
  }.freeze

  # ------------------------------------------------------------
  # 行のパターン。上から順に当てはめ、最初に一致したものを使う。
  # ------------------------------------------------------------
  LINE_RULES = [
    [/\A#\s*(.*)\z/,                          ->(m) { "コメント: #{m[1]}" }],
    [/\A<!--\s*(.*?)\s*-->\z/,                ->(m) { "コメント: #{m[1]}" }],
    [/\Aclass\s+(\S+)\s*<\s*(\S+)/,           ->(m) { "#{m[2]}を受け継いだ#{m[1]}クラスを定義する" }],
    [/\Aclass\s+(\S+)/,                       ->(m) { "#{m[1]}というクラスを定義する" }],
    [/\Amodule\s+(\S+)/,                      ->(m) { "#{m[1]}というモジュールを定義する" }],
    [/\Adef\s+self\.(\S+)/,                   ->(m) { "クラス全体で使える#{m[1]}という処理を定義する" }],
    [/\Adef\s+([^\s(]+)/,                     ->(m) { "#{m[1]}という処理を定義する" }],
    [/\Aend\z/,                               ->(_) { "まとまりの終わり" }],
    [/\Aprivate\z/,                           ->(_) { "ここから下は外部から呼べない処理" }],
    [/\Aprotected\z/,                         ->(_) { "ここから下は限定公開の処理" }],

    [/\Avalidates\s+:(\w+)(.*)/,              ->(m) { "#{m[1]}について#{validation_detail(m[2])}を確かめる" }],
    [/\Ahas_many\s+:(\w+)(.*)/,               ->(m) { "複数の#{m[1]}を持つ#{dependent_note(m[2])}" }],
    [/\Ahas_one\s+:(\w+)/,                    ->(m) { "1つの#{m[1]}を持つ" }],
    [/\Abelongs_to\s+:(\w+)/,                 ->(m) { "#{m[1]}に属する" }],
    [/\Ascope\s+:(\w+)/,                      ->(m) { "#{m[1]}という名前で絞り込み条件を定義する" }],
    [/\Aenum\s+(\w+):/,                       ->(m) { "#{m[1]}の選択肢に名前と数値を対応させる" }],
    [/\Ahas_secure_password/,                 ->(_) { "パスワードを安全に扱う仕組みを組み込む" }],
    [/\Abefore_action\s+:(\w+)(.*)/,          ->(m) { "処理の前に#{m[1]}を実行する#{action_scope(m[2])}" }],
    [/\Abefore_save/,                         ->(_) { "保存の直前に処理を行う" }],
    [/\Abefore_validation\s+:(\w+)/,          ->(m) { "検証の前に#{m[1]}を実行する" }],

    [/\A(@?\w+)\s*=\s*(\w+)\.new\((.*)\)/,    ->(m) { "#{m[3]}を使って#{m[2]}を新しく用意し、#{m[1]}に入れる" }],
    [/\A(@?\w+)\s*=\s*(\w+)\.find\((.*)\)/,   ->(m) { "#{m[3]}で#{m[2]}を1件探し、#{m[1]}に入れる" }],
    [/\A(@?\w+)\s*=\s*(\w+)\.find_by\((.*)\)/, ->(m) { "#{m[3]}という条件で#{m[2]}を1件探し、#{m[1]}に入れる" }],
    [/\A(@?\w+)\s*=\s*(\w+)\.where\((.*)\)/,  ->(m) { "#{m[3]}という条件で#{m[2]}を絞り込み、#{m[1]}に入れる" }],
    [/\A(@?\w+)\s*=\s*(\w+)\.all/,            ->(m) { "#{m[2]}をすべて取り出し、#{m[1]}に入れる" }],
    [/\A(@?\w+)\s*=\s*(.+)/,                  ->(m) { "#{m[2]}を#{m[1]}に入れる" }],

    [/\Aif\s+(.+)/,                           ->(m) { "もし#{m[1]}なら" }],
    [/\Aelsif\s+(.+)/,                        ->(m) { "そうでなくて、もし#{m[1]}なら" }],
    [/\Aelse\z/,                              ->(_) { "そうでなければ" }],
    [/\Aunless\s+(.+)/,                       ->(m) { "#{m[1]}でなければ" }],
    [/\Areturn\s+if\s+(.+)/,                  ->(m) { "#{m[1]}なら、何もせず戻る" }],
    [/\Areturn\s*\z/,                         ->(_) { "ここで処理を終えて戻る" }],

    [/\Aredirect_to\s+([^,]+),\s*notice:\s*(.+)/, ->(m) { "#{m[1]}へ移動し、#{m[2]}と知らせる" }],
    [/\Aredirect_to\s+([^,]+),\s*alert:\s*(.+)/,  ->(m) { "#{m[1]}へ移動し、#{m[2]}と警告する" }],
    [/\Aredirect_to\s+(.+)/,                  ->(m) { "#{m[1]}へ移動する" }],
    [/\Arender\s+:(\w+)(.*)/,                 ->(m) { "#{m[1]}の画面を表示する#{render_status(m[2])}" }],
    [/\Arender\s+(.+)/,                       ->(m) { "#{m[1]}を表示する" }],
    [/params\.require\(:(\w+)\)\.permit\((.*)\)/, ->(m) { "#{m[1]}の中の#{m[2]}だけ受け取りを許可する" }],

    [/\Aresources\s+:(\w+)(.*)/,              ->(m) { "#{m[1]}の経路を作る#{resource_scope(m[2])}" }],
    [/\Aresource\s+:(\w+)/,                   ->(m) { "#{m[1]}の経路を単数形で作る" }],
    [/\Aroot\s+(.+)/,                         ->(m) { "トップページを#{m[1]}にする" }],
    [/\Anamespace\s+:(\w+)/,                  ->(m) { "#{m[1]}という区画を作る" }],
    [/\Amember\s+do/,                         ->(_) { "個別の1件に対する経路をここに書く" }],
    [/\Acollection\s+do/,                     ->(_) { "一覧全体に対する経路をここに書く" }],
    [/\A(get|post|patch|put|delete)\s+(.+)/,  ->(m) { "#{m[2]} への#{http_method(m[1])}の経路を作る" }],

    [/\Acreate_table\s+:(\w+)/,               ->(m) { "#{m[1]}という表を作る" }],
    [/\At\.(\w+)\s+:(\w+)(.*)/,               ->(m) { "#{m[2]}という#{column_type(m[1])}の列を作る#{column_option(m[3])}" }],
    [/\At\.timestamps/,                       ->(_) { "作成日時と更新日時の列を用意する" }],
    [/\Aadd_column\s+:(\w+),\s*:(\w+),\s*:(\w+)(.*)/, ->(m) { "#{m[1]}の表に#{m[2]}という#{column_type(m[3])}の列を追加する" }],
    [/\Aremove_column\s+:(\w+),\s*:(\w+)/,    ->(m) { "#{m[1]}の表から#{m[2]}の列を削除する" }],
    [/\Aadd_index\s+:(\w+),\s*:(\w+)(.*)/,    ->(m) { "#{m[1]}の#{m[2]}に索引を付ける#{unique_note(m[3])}" }],

    [/\A(\w+)\.each\s+do\s*\|(\w+)\|/,        ->(m) { "#{m[1]}から1件ずつ#{m[2]}として取り出す" }],
    [/\Aputs\s+(.+)/,                         ->(m) { "#{m[1]}を画面に出力する" }],
    [/\A(\w+)\.save\z/,                       ->(m) { "#{m[1]}を保存する" }],
    [/\A(\w+)\.destroy\z/,                    ->(m) { "#{m[1]}を削除する" }],
    [/\A(\w+)\.update\((.*)\)/,               ->(m) { "#{m[1]}の#{m[2]}を更新する" }],

    [/\A<!DOCTYPE html>/i,                    ->(_) { "HTML5で書くという宣言" }],
    [/\A<html[^>]*lang="(\w+)"/,              ->(m) { "#{m[1] == "ja" ? "日本語" : m[1]}のページであると伝える" }],
    [/\A<meta\s+charset="([^"]+)"/,           ->(m) { "文字コードを#{m[1]}に指定する" }],
    [/\A<title>(.*?)<\/title>/,               ->(m) { "ページの題名を「#{m[1]}」にする" }],
    [/\A<h([1-6])>(.*?)<\/h[1-6]>/,           ->(m) { "#{m[1]}番目の大きさの見出しとして「#{m[2]}」を表示する" }],
    [/\A<p>(.*?)<\/p>/,                       ->(m) { "段落として「#{m[1]}」を表示する" }],
    [/\A<a\s+href="([^"]*)"[^>]*>(.*?)<\/a>/, ->(m) { "「#{m[2]}」を#{m[1]}へのリンクにする" }],
    [/\A<img\s+src="([^"]*)"/,                ->(m) { "#{m[1]} の画像を表示する" }],
    [/\A<(ul|ol)>/,                           ->(m) { "#{m[1] == "ul" ? "順序なし" : "順序あり"}の箇条書きを始める" }],
    [/\A<li>(.*?)<\/li>/,                     ->(m) { "箇条書きの項目として「#{m[1]}」を並べる" }],
    [/\A<input\s+type="([^"]+)"/,             ->(m) { "#{input_type(m[1])}の入力欄を置く" }],
    [/\A<button[^>]*>(.*?)<\/button>/,        ->(m) { "「#{m[1]}」というボタンを置く" }],
    [/\A<(\w+)[^>]*>\z/,                      ->(m) { "#{m[1]} の要素を開始する" }],
    [/\A<\/(\w+)>\z/,                         ->(m) { "#{m[1]} の要素を閉じる" }]
  ].freeze

  # 行ルールから呼ばれる補助。表現を整えるだけの small な処理をまとめている。
  class << self
    def validation_detail(rest)
      details = []
      details << "空でないこと" if rest.include?("presence")
      details << "重複しないこと" if rest.include?("uniqueness")
      details << "数値であること" if rest.include?("numericality")
      details << "文字数の制限" if rest.include?("length")
      details << "書式" if rest.include?("format")
      details.empty? ? "指定の条件" : details.join("と")
    end

    def dependent_note(rest)
      rest.include?("destroy") ? "(自分が消えたら一緒に消す)" : ""
    end

    def action_scope(rest)
      return "(#{Regexp.last_match(1)}のときだけ)" if rest =~ /only:\s*\[(.*?)\]/

      ""
    end

    def render_status(rest)
      rest.include?("unprocessable_entity") ? "(入力エラーとして返す)" : ""
    end

    def resource_scope(rest)
      return "(#{Regexp.last_match(1)}だけ)" if rest =~ /only:\s*\[(.*?)\]/
      return "(#{Regexp.last_match(1)}以外)" if rest =~ /except:\s*\[(.*?)\]/

      "(一覧・詳細・作成・編集・削除など7つ)"
    end

    def http_method(verb)
      { "get" => "表示", "post" => "新規作成", "patch" => "更新", "put" => "更新", "delete" => "削除" }[verb]
    end

    def column_type(type)
      DICTIONARY[type] || type
    end

    def column_option(rest)
      rest.include?("null: false") ? "(空は不可)" : ""
    end

    def unique_note(rest)
      rest.include?("unique") ? "(重複も禁止する)" : ""
    end

    def input_type(type)
      {
        "text" => "文字", "email" => "メールアドレス", "password" => "パスワード",
        "number" => "数値", "checkbox" => "チェックボックス", "radio" => "ラジオボタン",
        "submit" => "送信ボタン", "date" => "日付"
      }[type] || type
    end
  end

  attr_reader :code

  def initialize(code)
    @code = code.to_s.delete("\r")
  end

  # 1行ごとの意味。空行は飛ばす。
  def line_translations
    code.split("\n").each_with_index.filter_map do |raw, index|
      next if raw.strip.empty?

      [index + 1, raw, translate_line(raw.strip)]
    end
  end

  # コード中に現れた単語だけを辞書から拾う。
  # 単純な include? だと "create" の中の "eq" のような部分一致を拾ってしまうため、
  # 単語の区切りを見て一致を判定する。
  def words
    found = DICTIONARY.keys.select { |word| whole_word?(word) }
    # 長い語から並べ、意味の濃いものが先に目に入るようにする
    found.sort_by { |w| [-w.length, w] }.map { |w| [w, DICTIONARY[w]] }
  end

  # 全行の意味をつないだ通し訳。
  # 1行ごとの訳を並べるだけでは読みにくいので、
  # 「まとまりの終わり」のような単体では意味の薄い行は省き、
  # 文章として流れるように接続する。
  SKIP_IN_PROSE = ["まとまりの終わり"].freeze

  def prose
    meanings = line_translations.filter_map { |_number, _raw, meaning| meaning }
    meanings = meanings.reject { |m| SKIP_IN_PROSE.include?(m) }

    return nil if meanings.empty?

    # 読点でつなぎ、最後だけ句点で締める
    body = meanings.each_with_index.map do |meaning, index|
      last = index == meanings.size - 1
      last ? meaning : "#{meaning}、"
    end.join

    "#{body}。".gsub("、。", "。").gsub("。。", "。")
  end

  # 全体の要約。
  # 「何という名前の、何であるか」を主語にし、そこで具体的に何をしているかを
  # 中身から読み取って続ける。単なるキーワードの有無ではなく、
  # 対象の名前まで拾うことで内容のある一文にする。
  def summary
    subject = detect_subject
    activities = detect_activities

    return subject if activities.empty?

    "#{subject}#{activities.join('、')}。"
  end

  # このコードがアプリの中でどんな役割を担うのかを説明する。
  # 要約が「何をしているか」なのに対し、こちらは「なぜ必要か」を伝える。
  ROLE_DESCRIPTIONS = {
    controller: "利用者の操作を受け取り、必要なデータを用意して、どの画面を見せるかを決める橋渡し役です。" \
                "ブラウザからの要求はまずここに届き、モデルとビューをつなぎます。",
    model: "データベースの1つの表に対応し、保存する値の決まりや他の表とのつながりを定めます。" \
           "「正しいデータだけを通す門番」の役割を持ちます。",
    migration: "データベースの設計図を書き換える指示書です。" \
               "一度実行すると記録が残り、チーム全員が同じ構造を再現できます。",
    routes: "どのURLに来たら、どの処理を動かすかの案内図です。" \
            "ここに書かれていないURLは開くことができません。",
    view: "利用者が実際に目にする画面の中身です。" \
          "コントローラが用意したデータを、見える形に組み立てます。",
    spec: "コードが期待どおり動くかを自動で確かめる仕組みです。" \
          "変更したときに、壊れていないかをすぐ検知できます。",
    html: "文書の構造を示すための記述です。" \
          "見出し・段落・リンクといった意味づけを行い、ブラウザに伝えます。"
  }.freeze

  def role
    ROLE_DESCRIPTIONS[detect_kind]
  end

  private

  # コードの種類を判定する。要約と役割説明の両方から使う。
  def detect_kind
    return :controller if code =~ /class\s+\w+Controller\s*</
    return :model      if code =~ /class\s+\w+\s*<\s*ApplicationRecord/
    return :migration  if code =~ /ActiveRecord::Migration|create_table|add_column|add_index/
    return :routes     if code =~ /Rails\.application\.routes\.draw/ || code =~ /^\s*resources\s+:/
    return :spec       if code =~ /RSpec\.describe|describe\s+["']|expect\(/
    return :view       if code =~ /form_with|link_to|render\s+["']|<%=/
    return :html       if code =~ /<!DOCTYPE html|<html|<div|<p>|<form/

    nil
  end

  # 「何のコードか」を、名前まで含めて特定する。
  def detect_subject
    if code =~ /class\s+(\w+)Controller\s*</
      "#{Regexp.last_match(1)}に関する画面の処理をまとめたコントローラです。"
    elsif code =~ /class\s+(\w+)\s*<\s*ApplicationRecord/
      "#{Regexp.last_match(1)}というデータの形を定めたモデルです。"
    elsif code =~ /RSpec\.describe\s+(\w+)/ || code =~ /describe\s+["']?(\w+)/
      "#{Regexp.last_match(1)}が正しく動くかを確かめるテストです。"
    elsif code =~ /class\s+(\w+)\s*<\s*ActiveRecord::Migration/
      "データベースの構造を変更するマイグレーションです。"
    elsif code =~ /Rails\.application\.routes\.draw/
      "URLとどの処理を結び付けるかを定めたルーティングです。"
    elsif code =~ /class\s+(\w+)/
      "#{Regexp.last_match(1)}というまとまりを定めたコードです。"
    elsif code =~ /\A\s*<!DOCTYPE html/i || code =~ /<html/
      "1ページ分のHTML文書です。"
    elsif code =~ /<\w+[^>]*>/
      "画面の見た目を組み立てるHTMLです。"
    elsif code =~ /create_table|add_column|add_index/
      "データベースの構造を変更するコードです。"
    elsif code =~ /^\s*(resources|root|namespace|get|post)\s/
      "URLと処理の対応を定めたルーティングです。"
    else
      "コードの断片です。"
    end
  end

  # 中で実際に行っていることを、対象の名前まで拾って並べる。
  def detect_activities
    items = []

    if (names = code.scan(/validates\s+:(\w+)/).flatten).any?
      items << "#{names.uniq.join('と')}の入力内容を検査し"
    end

    if (names = code.scan(/has_many\s+:(\w+)/).flatten).any?
      items << "#{names.uniq.join('と')}を複数持つ関係を定義し"
    end

    if (names = code.scan(/belongs_to\s+:(\w+)/).flatten).any?
      items << "#{names.uniq.join('と')}に属する関係を定義し"
    end

    if (actions = code.scan(/def\s+(index|show|new|create|edit|update|destroy)\b/).flatten).any?
      items << "#{actions.uniq.map { |a| ACTION_NAMES[a] }.join('・')}の処理を用意し"
    end

    items << "ログインの仕組みを用意し" if code =~ /has_secure_password|session\[|current_user/
    items << "処理の前に共通の下準備をし" if code.include?("before_action")

    if (models = code.scan(/(\w+)\.(?:where|find_by|find|all)\b/).flatten).any?
      items << "#{models.uniq.first}からデータを取り出し"
    end

    items << "条件によって処理を分岐し" if code =~ /^\s*if\s|unless\s/
    items << "受け取ってよい値を限定し" if code.include?("permit")
    items << "画面の表示や移動を指示し" if code =~ /redirect_to|render\s/

    if (tables = code.scan(/create_table\s+:(\w+)/).flatten).any?
      items << "#{tables.join('と')}という表を作成し"
    end

    if (paths = code.scan(/resources\s+:(\w+)/).flatten).any?
      items << "#{paths.join('と')}への経路を用意し"
    end

    return [] if items.empty?

    # 各項目は「〜し」で終わる形に揃えてあるので、
    # 最後だけ「〜しています」に変えて文として締める
    items[-1] = "#{items.last.sub(/し\z/, '')}しています"
    items
  end

  ACTION_NAMES = {
    "index" => "一覧",
    "show" => "詳細",
    "new" => "新規作成画面",
    "create" => "登録",
    "edit" => "編集画面",
    "update" => "更新",
    "destroy" => "削除"
  }.freeze

  # 単語として独立して現れているかを判定する。
  # 「?」で終わる語(exists? など)は \b が効かないため個別に扱う。
  def whole_word?(word)
    if word.end_with?("?")
      code.include?(word)
    else
      code.match?(/(?<![\w?])#{Regexp.escape(word)}(?![\w?])/)
    end
  end

  def translate_line(line)
    LINE_RULES.each do |pattern, builder|
      match = pattern.match(line)
      next unless match

      return self.class.instance_exec(match, &builder)
    end

    # 当てはまるパターンが無いときは、分からないことを正直に返す
    nil
  end
end
