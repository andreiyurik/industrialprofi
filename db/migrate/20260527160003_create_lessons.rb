class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.text :body
      t.text :task
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :lessons, :slug, unique: true
    add_index :lessons, [ :course_id, :position ]
  end
end
