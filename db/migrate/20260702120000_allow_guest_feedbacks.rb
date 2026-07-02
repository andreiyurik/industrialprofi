class AllowGuestFeedbacks < ActiveRecord::Migration[8.1]
  def change
    # Business inquiries (/business) arrive from training centers and employers
    # who have no learner account — their contact goes in the body.
    change_column_null :feedbacks, :user_id, true
  end
end
