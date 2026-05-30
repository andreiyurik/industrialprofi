class CreateLessonSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_suggestions do |t|
      t.references :lesson, null: false, foreign_key: true
      t.text :body_markdown, null: false
      t.string :section, null: false, default: "body"
      t.string :author_name, null: false
      t.string :author_contact
      t.string :status, null: false, default: "pending"
      t.text :reviewer_comment
      t.timestamps
    end

    add_index :lesson_suggestions, :status
  end
end
