module Admin
  # Messages to the founder — administrator-only (unlike content sections,
  # these are personal mail, not editorial work).
  class FeedbacksController < BaseController
    before_action :ensure_can_administer

    def index
      @feedbacks = Feedback.includes(:user).newest_first
      # Opening the inbox is reading it — clears the nav badge.
      Feedback.unread.update_all(read_at: Time.current)
    end
  end
end
