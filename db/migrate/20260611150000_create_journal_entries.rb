class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, foreign_key: true
      t.string :title

      t.timestamps
    end
    add_index :journal_entries, [ :user_id, :created_at ]
  end
end
