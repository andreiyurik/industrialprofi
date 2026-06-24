module Admin
  # The transparency log («Журнал действий») — read-only view of the append-only
  # AdminAction trail. Administrator-only: seeing who exercised power over people
  # and moderation is itself an administrator concern.
  class AdminActionsController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    # Action groups for the filter tabs — keeps the raw action types readable.
    CATEGORIES = {
      "roles"      => %w[user_role_changed user_access_changed],
      "moderation" => %w[suggestion_approved suggestion_rejected lesson_rolled_back],
      "bans"       => %w[user_suspended user_reinstated]
    }.freeze

    def index
      @category = params[:type] if CATEGORIES.key?(params[:type])
      @actor_id = params[:actor].presence
      # The actor dropdown lists who CAN act (small, fixed), not a DISTINCT scan
      # over the whole log — keeps the page cheap however large the log grows.
      @actors = User.where(role: %w[editor administrator]).order(:name)

      scope = AdminAction.includes(:actor)
      scope = scope.where(action: CATEGORIES[@category]) if @category
      scope = scope.where(actor_id: @actor_id) if @actor_id

      paginate(scope)
    end

    private
      # Keyset (cursor) pagination on the primary key — cheap at any depth, with
      # no COUNT and no OFFSET, so the log stays light however long it grows.
      # `before`/`after` carry the edge ids; filters reset the cursor.
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
