# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_08_17_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "snippet_id", null: false
    t.integer "level", default: 0, null: false
    t.text "input_text", null: false
    t.float "accuracy", default: 0.0, null: false
    t.integer "mistake_count", default: 0, null: false
    t.integer "duration_ms", default: 0, null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["snippet_id"], name: "index_attempts_on_snippet_id"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "snippets", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "user_id"
    t.string "title", null: false
    t.text "code", null: false
    t.text "explanation"
    t.string "language", default: "ruby", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "line_notes"
    t.text "summary"
    t.text "glossary"
    t.text "memo"
    t.index ["category_id"], name: "index_snippets_on_category_id"
    t.index ["user_id"], name: "index_snippets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "attempts", "snippets"
  add_foreign_key "attempts", "users"
  add_foreign_key "snippets", "categories"
  add_foreign_key "snippets", "users"
end
