class AddAvatarTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_token, :string
  end
end
