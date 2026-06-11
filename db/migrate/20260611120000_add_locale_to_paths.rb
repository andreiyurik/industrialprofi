class AddLocaleToPaths < ActiveRecord::Migration[8.1]
  def change
    add_column :paths, :locale, :string, null: false, default: "ru"
    add_index :paths, :locale
  end
end
