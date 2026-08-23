module Admin
  # Remove a curator's photo — the one moderation act a public face needs,
  # logged like every other action over people.
  class PhotosController < AdministratorController
    def destroy
      user = User.find(params[:user_id])
      ActiveRecord::Base.transaction do
        user.photo.purge_later
        record_admin_action("user_photo_removed", target: user, subject: user.name)
      end
      redirect_to admin_user_path(user), notice: t("admin.users.photo_removed", name: user.name)
    end
  end
end
