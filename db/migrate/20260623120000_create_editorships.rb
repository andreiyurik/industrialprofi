class CreateEditorships < ActiveRecord::Migration[8.1]
  # Per-profession edit access. An editor («Эксперт») may directly edit only the
  # professions granted here; admins edit everything and need no row. Access is
  # kept separate from authorship (paths.author_id = who created it / official vs
  # community) — this records who may maintain it.
  def change
    create_table :editorships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :path, null: false, foreign_key: true

      t.timestamps
    end

    add_index :editorships, [ :user_id, :path_id ], unique: true
  end
end
