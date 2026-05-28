class CreateLessonRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_revisions do |t|
      t.references :lesson, null: false, foreign_key: true
      t.references :lesson_suggestion, null: true, foreign_key: true
      t.integer :version, null: false
      t.string :section, null: false
      t.text :content_before
      t.text :content_after
      t.string :editor_name
      t.text :edit_reason
      t.string :source, null: false

      t.timestamps
    end

    add_index :lesson_revisions, [ :lesson_id, :version ], unique: true
  end
end
