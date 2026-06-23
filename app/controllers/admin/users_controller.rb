module Admin
  class UsersController < BaseController
    before_action :ensure_can_administer

    PER_PAGE = 50

    def index
      @page = [ params[:page].to_i, 1 ].max
      @paths = Path.ordered
      scope = User.includes(:editorships).order(created_at: :desc)
      if params[:q].present?
        q = "%#{User.sanitize_sql_like(params[:q].strip)}%"
        scope = scope.where("name LIKE :q OR email_address LIKE :q", q: q)
      end
      # One extra row tells us a next page exists without a second count query.
      records = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @has_more = records.size > PER_PAGE
      @users = records.first(PER_PAGE)
    end

    def update
      user = User.find(params[:id])

      if params[:user]&.key?(:editable_path_ids)
        update_access(user)
      elsif user == Current.user
        # Lockout guard: the last administrator must not demote themselves.
        redirect_to admin_users_path, alert: t("admin.users.cannot_change_own_role")
      elsif User.roles.key?(params.dig(:user, :role))
        user.update!(role: params[:user][:role])
        redirect_to admin_users_path,
          notice: t("admin.users.role_updated", name: user.name, role: t("admin.roles.#{user.role}"))
      else
        head :unprocessable_entity
      end
    end

    private
      # Which professions this editor may edit directly. The has_many :through
      # setter creates/destroys the Editorship rows to match the ticked boxes.
      def update_access(user)
        user.editable_path_ids = Array(params[:user][:editable_path_ids]).reject(&:blank?)
        redirect_to admin_users_path, notice: t("admin.users.access_updated", name: user.name)
      end
  end
end
