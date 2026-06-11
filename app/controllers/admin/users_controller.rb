module Admin
  class UsersController < BaseController
    before_action :ensure_can_administer

    def index
      @users = User.order(created_at: :desc)
      if params[:q].present?
        q = "%#{User.sanitize_sql_like(params[:q].strip)}%"
        @users = @users.where("name LIKE :q OR email_address LIKE :q", q: q)
      end
    end

    def update
      user = User.find(params[:id])

      if user == Current.user
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
  end
end
