class CreateGlossaryTerms < ActiveRecord::Migration[8.1]
  def change
    # A profession's abbreviations, each defined by the lesson that explains it —
    # the same shape as resources (a lesson's links). The dictionary pages derive
    # from these rows; there is no per-profession list to maintain.
    create_table :glossary_terms do |t|
      t.references :lesson, null: false, foreign_key: true
      t.string :abbr, null: false
      t.string :full, null: false
      t.string :note
      t.string :analog
      t.string :origin, null: false, default: "human"
      t.timestamps
    end
    add_index :glossary_terms, [ :lesson_id, :abbr ], unique: true
  end
end
