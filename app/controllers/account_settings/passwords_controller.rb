class AccountSettings::PasswordsController < ApplicationController
  def edit
  end

  def update
    user = Current.user

    unless user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = t("account.password_current_invalid")
      return render :edit, status: :unprocessable_entity
    end

    if user.update(password_params)
      redirect_to account_path, notice: t("account.password_updated")
    else
      flash.now[:alert] = user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def password_params
      params.expect(user: [ :password, :password_confirmation ])
    end
end
