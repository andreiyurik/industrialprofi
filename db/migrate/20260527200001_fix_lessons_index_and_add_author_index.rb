class FixLessonsIndexAndAddAuthorIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :lessons, name: "index_lessons_on_course_id_and_position"
    add_index :lessons, %i[path_id position]
    add_index :paths, :author_id
  end
end
