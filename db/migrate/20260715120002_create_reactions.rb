class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reactable, null: false, polymorphic: true

      t.timestamps
    end

    # One ❤️ per user per thing — the DB guard that makes create_or_find_by! race-safe.
    add_index :reactions, [ :user_id, :reactable_type, :reactable_id ],
      unique: true, name: "index_reactions_on_user_and_reactable"
  end
end
