class AddLandingToPaths < ActiveRecord::Migration[8.1]
  def change
    # The profession's «О профессии» landing: six content slots in one JSON
    # column (a new slot is code, not a migration) — see Path::Landing.
    add_column :paths, :landing, :json, null: false, default: {}
  end
end
