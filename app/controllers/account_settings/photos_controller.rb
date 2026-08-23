# A curator's photo from /account: picking a file uploads it at once (replacing
# the previous one), one click removes it. Members have no photo to manage.
class AccountSettings::PhotosController < ApplicationController
  before_action :ensure_photo_allowed

  def create
    if Current.user.update_photo(params.expect(:photo))
      redirect_to account_path, notice: t("account.photo_updated")
    else
      redirect_to account_path, alert: t("account.photo_invalid")
    end
  end

  def destroy
    Current.user.photo.purge_later
    redirect_to account_path, notice: t("account.photo_removed")
  end

  private
    def ensure_photo_allowed
      head :forbidden unless Current.user.photo_allowed?
    end
end
