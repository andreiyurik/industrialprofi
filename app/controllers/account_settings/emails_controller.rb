class AccountSettings::EmailsController < ApplicationController
  helper_method :email_change

  def edit
  end

  def create
    email = params[:email_address].to_s.strip.downcase

    if !email.match?(URI::MailTo::EMAIL_REGEXP)
      flash.now[:alert] = t("signup.invalid_email")
      return render :edit, status: :unprocessable_entity
    end

    if email == Current.user.email_address
      flash.now[:alert] = t("account.email_same")
      return render :edit, status: :unprocessable_entity
    end

    if User.where.not(id: Current.user.id).exists?(email_address: email)
      flash.now[:alert] = t("account.email_taken")
      return render :edit, status: :unprocessable_entity
    end

    code = email_change.start!(email)
    AccountMailer.email_change_code(email, code).deliver_later
    Rails.logger.info "Email change code for #{email}: #{code}" if Rails.env.development?
    redirect_to new_account_email_verification_path
  end

  private
    def email_change
      @email_change ||= EmailChange.new(session)
    end
end
