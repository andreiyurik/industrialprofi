module Admin
  # Messages to the founder, administrator-only — personal mail, not editorial work.
  class FeedbacksController < AdministratorController
    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      # Reached filtered from the dashboard's «заявки соавторов» callout.
      @coauthor_only = params[:only] == "coauthor"
      scope = Feedback.includes(:user).newest_first
      scope = scope.coauthor_applications if @coauthor_only

      @feedbacks, @has_more = paginate_window(scope.offset((@page - 1) * PER_PAGE), per_page: PER_PAGE)

      # Viewing marks read; a filtered view only clears what it shows, leaving
      # other unread mail alone.
      (@coauthor_only ? Feedback.coauthor_applications : Feedback).unread.update_all(read_at: Time.current)
    end
  end
end
