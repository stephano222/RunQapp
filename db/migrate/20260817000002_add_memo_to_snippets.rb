class AddMemoToSnippets < ActiveRecord::Migration[7.0]
  def change
    # 自分用の覚え書き。解説とは別に、学習者が自由に書ける欄。
    add_column :snippets, :memo, :text
  end
end
