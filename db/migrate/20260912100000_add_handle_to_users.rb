class AddHandleToUsers < ActiveRecord::Migration[8.1]
  def change
    # The public profile address (/u/:handle). Nil = no public profile.
    add_column :users, :handle, :string
    add_index :users, :handle, unique: true
    # Learning progress is private by default; contributions are always public.
    add_column :users, :show_progress, :boolean, default: false, null: false
  end
end
