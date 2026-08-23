require "digest"

class AddLandingToPaths < ActiveRecord::Migration[8.1]
  def up
    # The profession's «О профессии» landing: six content slots in one JSON
    # column (a new slot is code, not a migration) — see Path::Landing.
    add_column :paths, :landing, :json, null: false, default: {}
    restamp_pristine_digests
  end

  def down
    remove_column :paths, :landing
  end

  private
    # `landing` joins Path::IMPORTABLE_FIELDS, so every row's import digest
    # changes; a profession pristine under the old formula must stay pristine
    # — otherwise the importer would freeze them all and refresh nothing.
    # (Same NUL-joined formula as Importable#import_digest.)
    def restamp_pristine_digests
      select_all("SELECT id, title, description, position, status, kind, imported_digest FROM paths").each do |row|
        fields = row.values_at("title", "description", "position", "status", "kind")
        next unless row["imported_digest"] == Digest::SHA256.hexdigest(fields.join("\0"))

        restamped = Digest::SHA256.hexdigest((fields + [ {} ]).join("\0"))
        update "UPDATE paths SET imported_digest = #{quote(restamped)} WHERE id = #{row["id"].to_i}"
      end
    end
end
