class AddListedToPaths < ActiveRecord::Migration[8.1]
  def up
    add_column :paths, :listed, :boolean, default: true, null: false
    # Set here too: the importer skips a row frozen by a human edit.
    execute "UPDATE paths SET listed = FALSE WHERE locale = 'ru' AND author_id IS NULL AND slug NOT IN ('inzhener-asu-tp', 'elektrik')"
  end

  def down
    remove_column :paths, :listed
  end
end
