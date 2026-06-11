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

ActiveRecord::Schema[8.1].define(version: 2026_06_11_160000) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "lessons_count", default: 0, null: false
    t.integer "path_id", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "status", default: "published", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["path_id"], name: "index_courses_on_path_id"
    t.index ["slug"], name: "index_courses_on_slug", unique: true
    t.index ["status"], name: "index_courses_on_status"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lesson_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["lesson_id"], name: "index_journal_entries_on_lesson_id"
    t.index ["user_id", "created_at"], name: "index_journal_entries_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
  end

  create_table "lesson_completions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["lesson_id"], name: "index_lesson_completions_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_lesson_completions_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_lesson_completions_on_user_id"
  end

  create_table "lesson_revisions", force: :cascade do |t|
    t.text "content_after"
    t.text "content_before"
    t.datetime "created_at", null: false
    t.text "edit_reason"
    t.string "editor_name"
    t.integer "lesson_id", null: false
    t.integer "lesson_suggestion_id"
    t.string "section", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["lesson_id", "version"], name: "index_lesson_revisions_on_lesson_id_and_version", unique: true
    t.index ["lesson_id"], name: "index_lesson_revisions_on_lesson_id"
    t.index ["lesson_suggestion_id"], name: "index_lesson_revisions_on_lesson_suggestion_id"
  end

  create_table "lesson_suggestions", force: :cascade do |t|
    t.string "author_contact"
    t.string "author_name", null: false
    t.text "base_content"
    t.text "body_markdown"
    t.datetime "created_at", null: false
    t.text "edit_reason"
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
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "lesson", null: false
    t.integer "lesson_revisions_count", default: 0, null: false
    t.integer "path_id", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "stage"
    t.text "task"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_lessons_on_course_id_and_position"
    t.index ["course_id"], name: "index_lessons_on_course_id"
    t.index ["path_id", "position"], name: "index_lessons_on_path_id_and_position"
    t.index ["path_id"], name: "index_lessons_on_path_id"
    t.index ["slug"], name: "index_lessons_on_slug", unique: true
  end

  create_table "paths", force: :cascade do |t|
    t.integer "author_id"
    t.integer "courses_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "lessons_count", default: 0, null: false
    t.string "locale", default: "ru", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "status", default: "published", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_paths_on_author_id"
    t.index ["locale"], name: "index_paths_on_locale"
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

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "courses", "paths"
  add_foreign_key "journal_entries", "lessons"
  add_foreign_key "journal_entries", "users"
  add_foreign_key "lesson_completions", "lessons"
  add_foreign_key "lesson_completions", "users"
  add_foreign_key "lesson_revisions", "lesson_suggestions"
  add_foreign_key "lesson_revisions", "lessons"
  add_foreign_key "lesson_suggestions", "lessons"
  add_foreign_key "lessons", "courses"
  add_foreign_key "lessons", "paths"
  add_foreign_key "resources", "lessons"
  add_foreign_key "sessions", "users"
end
