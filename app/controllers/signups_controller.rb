class SignupsController < ApplicationController
  include SignupFlow

  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_signup_path, alert: t("auth.rate_limited") }

  def new
  end

  def create
    email = params[:email_address].to_s.strip.downcase

    if !email.match?(URI::MailTo::EMAIL_REGEXP)
      flash.now[:alert] = t("signup.invalid_email")
      render :new, status: :unprocessable_entity
    elsif User.exists?(email_address: email)
      redirect_to new_session_path, notice: t("signup.already_registered")
    else
      code = signup.start!(email)
      SignupsMailer.verification_code(email, code).deliver_later
      # No SMTP in development (Rails 8 no longer logs mail bodies) — surface
      # the code in the log so signup can be exercised locally.
      Rails.logger.info "Signup code for #{email}: #{code}" if Rails.env.development?
      redirect_to new_signup_verification_path
    end
  end
end
