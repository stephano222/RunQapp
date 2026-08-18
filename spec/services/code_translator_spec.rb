require "rails_helper"

# 和訳機能の中身。辞書と正規表現だけで動くので外部への通信はない。
#
# ここは「間違った訳を出しても画面は壊れない」ため、
# 不具合が起きても気づきにくい。過去に実際つまずいた形を残しておく。
RSpec.describe CodeTranslator do
  describe "#line_translations" do
    it "1行ずつ、行番号と原文と意味を返す" do
      result = described_class.new("resources :posts").line_translations

      number, raw, meaning = result.first
      expect(number).to eq(1)
      expect(raw).to eq("resources :posts")
      expect(meaning).to be_present
    end

    it "空行は飛ばして番号だけ進める" do
      result = described_class.new("resources :posts\n\nvalidates :title, presence: true").line_translations

      expect(result.map(&:first)).to eq([1, 3])
    end

    it "判断できない行でも落ちない" do
      expect { described_class.new("???????").line_translations }.not_to raise_error
    end

    it "改行コードの違いを吸収する" do
      result = described_class.new("resources :posts\r\nvalidates :title, presence: true").line_translations

      expect(result.size).to eq(2)
      expect(result.first[1]).not_to include("\r")
    end
  end

  describe "#words" do
    # 過去の不具合。単純な文字列の含有で探していたため、
    # create の中の eq、notice の中の it まで拾っていた。
    it "単語の途中に埋もれた文字は拾わない" do
      found = described_class.new("create").words.map(&:first)

      expect(found).not_to include("eq")
    end

    it "notice の中の it を拾わない" do
      found = described_class.new("flash[:notice]").words.map(&:first)

      expect(found).not_to include("it")
    end

    it "独立して現れた単語は拾う" do
      found = described_class.new("expect(user.name).to eq 'taro'").words.map(&:first)

      expect(found).to include("eq")
    end

    it "長い語から先に並べる" do
      lengths = described_class.new("resources :posts\nvalidates :title, presence: true")
                               .words.map { |word, _| word.length }

      expect(lengths).to eq(lengths.sort.reverse)
    end

    it "同じ単語を二度並べない" do
      found = described_class.new("resources :posts\nresources :users").words.map(&:first)

      expect(found).to eq(found.uniq)
    end

    it "辞書にない語ばかりなら空になる" do
      expect(described_class.new("zzz qqq").words).to be_empty
    end
  end

  describe "#summary と #role" do
    it "コード全体の役割を返す" do
      translator = described_class.new("resources :posts")

      expect(translator.role).to be_present
      expect(translator.summary).to be_present
    end

    # 要約は「それらしい言葉」ではなく、実際に書かれている名前を拾う。
    it "コードに出てくる名前を要約に含める" do
      summary = described_class.new("validates :title, presence: true").summary

      expect(summary).to include("title")
    end
  end

  describe "#prose" do
    it "各行の意味をつないで一続きの文にする" do
      prose = described_class.new("resources :posts\nvalidates :title, presence: true").prose

      expect(prose).to end_with("。")
      expect(prose).to include("、")
    end

    it "訳せる行がなければ何も返さない" do
      expect(described_class.new("???????").prose).to be_nil
    end
  end

  describe "区切り文字との衝突" do
    # 「コード : 意味」の形式で保存していたため、Rubyのシンボル :posts や
    # ハッシュの null: を区切りと誤認して分割されていた。
    it "シンボルを含む行でも原文をそのまま保てる" do
      _number, raw, _meaning = described_class.new("resources :posts").line_translations.first

      expect(raw).to eq("resources :posts")
    end

    it "コロンを含む行でも原文をそのまま保てる" do
      code = "add_column :users, :admin, :boolean, null: false"
      _number, raw, _meaning = described_class.new(code).line_translations.first

      expect(raw).to eq(code)
    end
  end

  describe "変わった入力" do
    it "空のコードでも落ちない" do
      expect { described_class.new("").line_translations }.not_to raise_error
    end

    it "nil でも落ちない" do
      expect { described_class.new(nil).words }.not_to raise_error
    end

    it "長いコードでも一定の速さで終わる" do
      long_code = (["validates :title, presence: true"] * 500).join("\n")

      elapsed = Benchmark.realtime do
        translator = described_class.new(long_code)
        translator.words
        translator.line_translations
        translator.prose
      end

      expect(elapsed).to be < 1.0
    end
  end
end
