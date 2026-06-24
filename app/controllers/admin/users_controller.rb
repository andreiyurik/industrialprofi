module Admin
  class UsersController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      @counts = filter_counts

      # The list is scan-and-navigate only; all management moved to the user
      # card (show), so the rows stay clean and the page filters/paginates well.
      scope = User.order(created_at: :desc)
      scope = scope.where(role: params[:role]) if User.roles.key?(params[:role])
      scope = scope.suspended if params[:status] == "suspended"
      if params[:q].present?
        q = "%#{User.sanitize_sql_like(params[:q].strip)}%"
        scope = scope.where("name LIKE :q OR email_address LIKE :q", q: q)
      end

      @total = scope.count
      @pages = [ (@total / PER_PAGE.to_f).ceil, 1 ].max
      @users = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE).to_a
      @has_more = @page < @pages
    end

    def show
      @user = User.find(params[:id])
      @paths = Path.ordered
      @started_paths = @user.started_paths
      @focus_path = @user.focus_path

      @completions_total = @user.lesson_completions.count
      @journal_total = @user.journal_entries.count
      @feedback_total = @user.feedbacks.count
      @completions = @user.lesson_completions.includes(lesson: :path).order(created_at: :desc).limit(8)
      @recent_journal = @user.journal_entries.includes(:lesson).ordered.limit(5)
      @user_sessions = @user.sessions.order(Arel.sql("COALESCE(last_active_at, created_at) DESC"))
      # Contributions link by author name (same key as Lesson#contributor_names),
      # since suggestions can be submitted without an account.
      @suggestions = LessonSuggestion.where(author_name: @user.name).includes(:lesson).order(created_at: :desc)
      @approved_contributions = @suggestions.count { |s| s.status == "approved" }
    end

    def update
      user = User.find(params[:id])

      if params[:user]&.key?(:editable_path_ids)
        update_access(user)
      elsif user == Current.user
        # Lockout guard: the last administrator must not demote themselves.
        redirect_to admin_users_path, alert: t("admin.users.cannot_change_own_role")
      elsif User.roles.key?(params.dig(:user, :role))
        previous = user.role
        ActiveRecord::Base.transaction do
          user.update!(role: params[:user][:role])
          record_admin_action("user_role_changed", target: user,
            subject: user.name, from: previous, to: user.role)
        end
        redirect_to admin_user_path(user),
          notice: t("admin.users.role_updated", name: user.name, role: t("admin.roles.#{user.role}"))
      else
        head :unprocessable_entity
      end
    end

    private
      # Tab counts for the filter bar — one grouped query plus the suspended count.
      def filter_counts
        by_role = User.group(:role).count
        {
          all: by_role.values.sum,
          member: by_role["member"].to_i,
          editor: by_role["editor"].to_i,
          administrator: by_role["administrator"].to_i,
          suspended: User.suspended.count
        }
      end

      # Which professions this editor may edit directly. The has_many :through
      # setter creates/destroys the Editorship rows to match the ticked boxes.
      def update_access(user)
        ActiveRecord::Base.transaction do
          user.editable_path_ids = Array(params[:user][:editable_path_ids]).reject(&:blank?)
          record_admin_action("user_access_changed", target: user,
            subject: user.name, paths: user.editable_paths.reload.map(&:title))
        end
        redirect_to admin_user_path(user), notice: t("admin.users.access_updated", name: user.name)
      end
  end
end
