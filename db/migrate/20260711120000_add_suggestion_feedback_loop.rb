class AddSuggestionFeedbackLoop < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :suggestion_emails, :boolean, default: true, null: false
    add_column :users, :suggestions_seen_at, :datetime
    add_column :users, :suggestion_digest_sent_at, :datetime

    add_column :lesson_suggestions, :reviewed_at, :datetime
    add_column :lesson_suggestions, :outcome_notified_at, :datetime
  end
end
