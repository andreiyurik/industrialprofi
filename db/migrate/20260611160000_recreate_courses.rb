class RecreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :path, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0, null: false
      t.string :status, default: "published", null: false
      t.integer :lessons_count, default: 0, null: false
      t.timestamps
    end
    add_index :courses, :slug, unique: true
    add_index :courses, :status

    add_column :paths, :courses_count, :integer, default: 0, null: false

    # Nullable at the DB level so a production `db:migrate` over existing lessons
    # doesn't fail; the seed loader backfills it and Lesson's required
    # `belongs_to :course` enforces presence at the app layer afterwards.
    add_reference :lessons, :course, null: true, foreign_key: true
    add_index :lessons, [ :course_id, :position ]
  end
end
