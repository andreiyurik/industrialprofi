class AddFieldToPaths < ActiveRecord::Migration[8.1]
  def up
    add_column :paths, :field, :string, default: "industry", null: false
    # Set here too: the importer skips a row frozen by a human edit.
    execute "UPDATE paths SET field = 'hobby' WHERE slug = 'fotograf-videograf'"
  end

  def down
    remove_column :paths, :field
  end
end
