class AccountSettings::EmailVerificationsController < ApplicationController
  before_action :ensure_pending_email_change
  helper_method :email_change

  def new
  end

  def create
    if email_change.verify(params[:code])
      Current.user.update!(email_address: email_change.email_address)
      email_change.clear!
      redirect_to account_path, notice: t("account.email_updated")
    else
      flash.now[:alert] = email_change.expired? ? t("signup.expired") : t("signup.code_invalid")
      render :new, status: :unprocessable_entity
    end
  end

  private
    def ensure_pending_email_change
      redirect_to edit_account_email_path unless email_change.pending?
    end

    def email_change
      @email_change ||= EmailChange.new(session)
    end
end
