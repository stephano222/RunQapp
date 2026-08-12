class CreateSnippets < ActiveRecord::Migration[7.0]
  def change
    create_table :snippets do |t|
      t.references :category, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :title, null: false
      t.text :code, null: false
      t.text :explanation
      t.string :language, null: false, default: "ruby"

      t.timestamps
    end
  end
end
