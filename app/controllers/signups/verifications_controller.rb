class Signups::VerificationsController < ApplicationController
  include SignupFlow

  before_action :ensure_pending_signup
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_signup_verification_path, alert: t("auth.rate_limited") }

  def new
  end

  def create
    if signup.verify(params[:code])
      redirect_to new_signup_completion_path
    else
      flash.now[:alert] = signup.expired? ? t("signup.expired") : t("signup.code_invalid")
      render :new, status: :unprocessable_entity
    end
  end

  private
    def ensure_pending_signup
      redirect_to new_signup_path unless signup.pending?
    end
end
