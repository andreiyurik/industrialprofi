class AddExpertVerificationToPaths < ActiveRecord::Migration[8.1]
  def change
    add_column :paths, :verified_at, :datetime
    add_column :paths, :verified_by_id, :integer
  end
end
