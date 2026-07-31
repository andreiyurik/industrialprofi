module Admin
  # Messages to the founder — administrator-only (unlike content sections,
  # these are personal mail, not editorial work).
  class FeedbacksController < AdministratorController
    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      # The dashboard "заявки соавторов" callout links here filtered, so the
      # founder triages applications without scrolling the whole inbox.
      @coauthor_only = params[:only] == "coauthor"
      scope = Feedback.includes(:user).newest_first
      scope = scope.coauthor_applications if @coauthor_only

      @feedbacks, @has_more = paginate_window(scope.offset((@page - 1) * PER_PAGE), per_page: PER_PAGE)

      # Opening the inbox is reading it — clears the nav badge. A filtered view
      # only clears what it actually shows, so unseen general messages stay unread.
      (@coauthor_only ? Feedback.coauthor_applications : Feedback).unread.update_all(read_at: Time.current)
    end
  end
end
