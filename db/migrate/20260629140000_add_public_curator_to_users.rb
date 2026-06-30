class AddPublicCuratorToUsers < ActiveRecord::Migration[8.1]
  # Opt-in public recognition: an editor may choose to be shown as the curator of
  # the professions they maintain, with a short credentials line (headline). Off
  # by default — a person's name is never exposed without consent.
  def change
    add_column :users, :public_curator, :boolean, default: false, null: false
    add_column :users, :headline, :string
  end
end
