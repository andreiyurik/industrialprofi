class CreateMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :maps do |t|
      t.references :user, null: false, index: { unique: true }
      # The official profession the map is an overlay on — nil once it is deleted.
      t.references :path, index: true
      t.string :title, null: false
      t.text :description
      t.integer :follows_count, null: false, default: 0
      t.timestamps
    end

    # Only the DIFFERENCE from the profession, never a copy of it: a map that
    # keeps every lesson stores no rows at all.
    create_table :map_items do |t|
      t.references :map, null: false, index: false
      # An overlay on a catalog lesson: `excluded` = the author took it off the
      # map, `note` = their comment to the learner under it.
      t.references :lesson, index: true
      t.boolean :excluded, null: false, default: false
      # Or the author's own link (title + url + note), hung under one of the
      # map's lessons or loose at the end.
      t.references :after_lesson, index: true
      t.integer :position, null: false, default: 0
      t.string :title
      t.string :url
      t.string :note
      t.timestamps
    end
    add_index :map_items, [ :map_id, :position ]

    create_table :map_follows do |t|
      t.references :map, null: false
      t.references :user, null: false, index: false
      t.timestamps
    end
    add_index :map_follows, [ :user_id, :map_id ], unique: true
  end
end
