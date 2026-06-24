module Admin
  # The transparency log («Журнал действий») — read-only view of the append-only
  # AdminAction trail. Administrator-only: seeing who exercised power over people
  # and moderation is itself an administrator concern.
  class AdminActionsController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      # One extra row tells us a next page exists without a second count query.
      records = AdminAction.includes(:actor).ordered
                           .offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @has_more = records.size > PER_PAGE
      @admin_actions = records.first(PER_PAGE)
    end
  end
end
