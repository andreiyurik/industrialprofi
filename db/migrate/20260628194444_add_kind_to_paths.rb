class AddKindToPaths < ActiveRecord::Migration[8.1]
  def change
    add_column :paths, :kind, :string, default: "role", null: false
  end
end
