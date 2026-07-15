class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.integer :reactions_count, null: false, default: 0

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :published_at
  end
end
