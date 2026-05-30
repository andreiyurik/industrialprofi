class CreatePaths < ActiveRecord::Migration[8.1]
  def change
    create_table :paths do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.integer :author_id
      t.string :status, null: false, default: "published"
      t.integer :courses_count, null: false, default: 0

      t.timestamps
    end

    add_index :paths, :slug, unique: true
    add_index :paths, :status
    add_index :paths, :position
  end
end
