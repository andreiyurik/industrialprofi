module Admin
  # «Журнал действий» — administrator-only: seeing who exercised power over people
  # and moderation is itself an administrator concern.
  class AdminActionsController < AdministratorController
    PER_PAGE = 50

    # Action groups for the filter tabs — keeps the raw action types readable.
    CATEGORIES = {
      "roles"      => %w[user_role_changed user_access_changed coauthor_approved],
      "moderation" => %w[suggestion_approved suggestion_rejected lesson_rolled_back],
      "content"    => %w[lesson_created_live lesson_deleted_live
                          path_created path_status_changed path_deleted
                          path_verified path_unverified
                          course_created course_status_changed course_deleted],
      "bans"       => %w[user_suspended user_reinstated]
    }.freeze

    def index
      @category = params[:type] if CATEGORIES.key?(params[:type])
      @actor_id = params[:actor].presence
      # Who CAN act (small, fixed) — not a DISTINCT scan over the growing log.
      @actors = User.where(role: %w[editor administrator]).order(:name)

      scope = AdminAction.includes(:actor)
      scope = scope.where(action: CATEGORIES[@category]) if @category
      scope = scope.where(actor_id: @actor_id) if @actor_id

      paginate(scope)
    end

    private
      # No COUNT/OFFSET, so cheap at any depth. The category filter's IN clause is
      # deliberately unindexed — bounded by category size, negligible at this volume.
      def paginate(scope)
        if (after = params[:after]).present?
          rows = scope.where("admin_actions.id > ?", after).order(id: :asc).limit(PER_PAGE + 1).to_a
          @has_newer = rows.size > PER_PAGE
          @admin_actions = rows.first(PER_PAGE).reverse
          @has_older = true
        else
          relation = scope.order(id: :desc).limit(PER_PAGE + 1)
          relation = relation.where("admin_actions.id < ?", params[:before]) if params[:before].present?
          rows = relation.to_a
          @has_older = rows.size > PER_PAGE
          @admin_actions = rows.first(PER_PAGE)
          @has_newer = params[:before].present?
        end

        @newer_cursor = @admin_actions.first&.id
        @older_cursor = @admin_actions.last&.id
        @filtered = @category.present? || @actor_id.present?
      end
  end
end
