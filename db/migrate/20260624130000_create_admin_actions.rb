class CreateAdminActions < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_actions do |t|
      # Who acted. Nullified (not blocked) if that admin later deletes their
      # own account — the log entry survives them, like a wiki's Special:Log
      # keeps the username text after the account is gone.
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }

      t.string :action, null: false

      # What was acted on. Polymorphic + nullable: kept for future filtering,
      # but the human-readable facts are denormalized into `details`, so an
      # entry stays meaningful even after its target row is destroyed.
      t.references :target, polymorphic: true

      t.json :details, null: false, default: {}

      # Append-only: rows are created and never updated, so no updated_at.
      t.datetime :created_at, null: false
    end

    add_index :admin_actions, :created_at
  end
end
