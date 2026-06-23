class AddImportProvenanceToContent < ActiveRecord::Migration[8.1]
  # Phase 0: make the DATABASE the single source of truth and the YAML/AI
  # importer a create-only feed that can never overwrite human work.
  #
  #   origin           — who authored the row: "human" (default — anything made
  #                      in-app/console), "seed" (YAML importer), "ai" (Phase 4).
  #   imported_digest  — content hash at last import; lets a re-import tell a
  #                      pristine importer-owned row (safe to refresh) from one a
  #                      human has since changed (frozen — skipped forever).
  #
  # Resources only carry `origin` (their edit-safety is gated by the parent
  # lesson being pristine), so they need no digest.
  def up
    add_column :paths,   :origin, :string, null: false, default: "human"
    add_column :paths,   :imported_digest, :string
    add_column :courses, :origin, :string, null: false, default: "human"
    add_column :courses, :imported_digest, :string
    add_column :lessons, :origin, :string, null: false, default: "human"
    add_column :lessons, :imported_digest, :string
    add_column :resources, :origin, :string, null: false, default: "human"

    # Everything that exists today was born from the YAML seed importer.
    execute "UPDATE paths SET origin = 'seed'"
    execute "UPDATE courses SET origin = 'seed'"
    execute "UPDATE lessons SET origin = 'seed'"
    execute "UPDATE resources SET origin = 'seed'"
  end

  def down
    remove_column :paths,   :origin
    remove_column :paths,   :imported_digest
    remove_column :courses, :origin
    remove_column :courses, :imported_digest
    remove_column :lessons, :origin
    remove_column :lessons, :imported_digest
    remove_column :resources, :origin
  end
end
