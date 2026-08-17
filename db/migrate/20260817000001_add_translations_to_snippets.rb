class AddTranslationsToSnippets < ActiveRecord::Migration[7.0]
  def change
    # 1行ごとの読み下し(「行:意味」を改行区切りで持つ)
    add_column :snippets, :line_notes, :text
    # コード全体を日本語で言い換えた一文
    add_column :snippets, :summary, :text
    # コード中の英単語とその意味(「単語:意味」を改行区切りで持つ)
    add_column :snippets, :glossary, :text
  end
end
