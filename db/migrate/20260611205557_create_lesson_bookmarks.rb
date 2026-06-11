class CreateLessonBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true

      t.timestamps
    end

    add_index :lesson_bookmarks, [ :user_id, :lesson_id ], unique: true
  end
end
