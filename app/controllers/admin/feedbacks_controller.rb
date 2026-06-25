module Admin
  # Messages to the founder — administrator-only (unlike content sections,
  # these are personal mail, not editorial work).
  class FeedbacksController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      # Fetch one extra to learn if a next page exists without a second query.
      records = Feedback.includes(:user).newest_first
                        .offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @has_more = records.size > PER_PAGE
      @feedbacks = records.first(PER_PAGE)

      # Opening the inbox is reading it — clears the nav badge.
      Feedback.unread.update_all(read_at: Time.current)
    end
  end
end
