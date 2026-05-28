class AddLessonRevisionsCountToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :lesson_revisions_count, :integer, default: 0, null: false
  end
end
