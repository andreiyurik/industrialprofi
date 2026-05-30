class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :path, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.integer :lessons_count, null: false, default: 0

      t.timestamps
    end

    add_index :courses, [ :path_id, :position ]
  end
end
