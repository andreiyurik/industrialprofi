class AccountSettings::DeletionsController < ApplicationController
  def new
  end

  def create
    unless Current.user.authenticate(params[:password].to_s)
      flash.now[:alert] = t("account.password_invalid_for_deletion")
      return render :new, status: :unprocessable_entity
    end

    user = Current.user
    Current.session = nil
    user.destroy!
    reset_session
    cookies.delete(:session_token)
    redirect_to root_path, notice: t("account.deleted")
  end
end
