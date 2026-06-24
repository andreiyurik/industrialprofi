module Admin
  # Suspend (create) / reinstate (destroy) a user account — a reversible ban.
  # Administrator-only, like role and access management.
  class SuspensionsController < BaseController
    before_action :ensure_can_administer
    before_action :set_user

    def create
      # Lockout guard: an admin must not ban themselves out of the platform.
      if @user == Current.user
        return redirect_to admin_users_path, alert: t("admin.users.cannot_suspend_self")
      end

      ActiveRecord::Base.transaction do
        @user.suspend!
        record_admin_action("user_suspended", target: @user, subject: @user.name)
      end
      redirect_to admin_users_path, notice: t("admin.users.suspended", name: @user.name)
    end

    def destroy
      ActiveRecord::Base.transaction do
        @user.reinstate!
        record_admin_action("user_reinstated", target: @user, subject: @user.name)
      end
      redirect_to admin_users_path, notice: t("admin.users.reinstated", name: @user.name)
    end

    private
      def set_user
        @user = User.find(params[:user_id])
      end
  end
end
