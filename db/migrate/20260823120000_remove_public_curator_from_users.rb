class RemovePublicCuratorFromUsers < ActiveRecord::Migration[8.1]
  def change
    # Curating is public by role now: a grant puts the name on the map.
    remove_column :users, :public_curator, :boolean, default: false, null: false
  end
end
