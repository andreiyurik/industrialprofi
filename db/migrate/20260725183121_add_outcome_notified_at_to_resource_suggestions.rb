class AddOutcomeNotifiedAtToResourceSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_column :resource_suggestions, :outcome_notified_at, :datetime
  end
end
