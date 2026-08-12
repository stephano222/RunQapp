class CreateAttempts < ActiveRecord::Migration[7.0]
  def change
    create_table :attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :snippet, null: false, foreign_key: true
      t.integer :level, null: false, default: 0
      t.text :input_text, null: false
      t.float :accuracy, null: false, default: 0.0
      t.integer :mistake_count, null: false, default: 0
      t.integer :duration_ms, null: false, default: 0
      t.boolean :correct, null: false, default: false

      t.timestamps
    end
  end
end
