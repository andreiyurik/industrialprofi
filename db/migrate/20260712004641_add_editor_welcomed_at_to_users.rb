class AddEditorWelcomedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :editor_welcomed_at, :datetime

    # Editors promoted before this feature shipped shouldn't suddenly get a
    # welcome letter — mark them as already greeted.
    reversible do |dir|
      dir.up { execute "UPDATE users SET editor_welcomed_at = CURRENT_TIMESTAMP WHERE role = 'editor'" }
    end
  end
end
