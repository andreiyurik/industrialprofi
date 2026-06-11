class AddLearningReminderToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :reminder_emails, :boolean, null: false, default: true
    add_column :users, :reminded_at, :datetime
  end
end
