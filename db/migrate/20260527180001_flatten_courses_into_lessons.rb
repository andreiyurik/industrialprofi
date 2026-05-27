class FlattenCoursesIntoLessons < ActiveRecord::Migration[8.1]
  def up
    add_reference :lessons, :path, null: true, foreign_key: true
    add_column :lessons, :stage, :string

    execute <<~SQL
      UPDATE lessons
      SET path_id = courses.path_id,
          stage = courses.title
      FROM courses
      WHERE lessons.course_id = courses.id
    SQL

    change_column_null :lessons, :path_id, false

    remove_reference :lessons, :course, foreign_key: true

    drop_table :courses

    rename_column :paths, :courses_count, :lessons_count
    execute "UPDATE paths SET lessons_count = (SELECT COUNT(*) FROM lessons WHERE lessons.path_id = paths.id)"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
