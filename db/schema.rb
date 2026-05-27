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

ActiveRecord::Schema[8.1].define(version: 2026_05_27_205221) do
  create_table "lesson_suggestions", force: :cascade do |t|
    t.string "author_contact"
    t.string "author_name", null: false
    t.text "body_markdown", null: false
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.text "reviewer_comment"
    t.string "section", default: "body", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_lesson_suggestions_on_lesson_id"
    t.index ["status"], name: "index_lesson_suggestions_on_status"
  end

  create_table "lessons", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "lesson", null: false
    t.integer "path_id", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "stage"
    t.text "task"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["path_id", "position"], name: "index_lessons_on_path_id_and_position"
    t.index ["path_id"], name: "index_lessons_on_path_id"
    t.index ["slug"], name: "index_lessons_on_slug", unique: true
  end

  create_table "paths", force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "lessons_count", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "status", default: "published", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_paths_on_author_id"
    t.index ["position"], name: "index_paths_on_position"
    t.index ["slug"], name: "index_paths_on_slug", unique: true
    t.index ["status"], name: "index_paths_on_status"
  end

  create_table "resources", force: :cascade do |t|
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "kind", default: "document", null: false
    t.integer "lesson_id", null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["lesson_id", "position"], name: "index_resources_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_resources_on_lesson_id"
  end

  add_foreign_key "lesson_suggestions", "lessons"
  add_foreign_key "lessons", "paths"
  add_foreign_key "resources", "lessons"
end
