class AccountController < ApplicationController
  before_action :init_errors

  def show
  end

  def update
    if Current.user.update(name_params)
      redirect_to account_path, notice: t("account.name_updated")
    else
      @name_errors = Current.user.errors.full_messages
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    user = Current.user

    unless user.authenticate(params[:current_password].to_s)
      @password_errors = [ t("account.password_current_invalid") ]
      return render :show, status: :unprocessable_entity
    end

    if user.update(password_params)
      redirect_to account_path, notice: t("account.password_updated")
    else
      @password_errors = user.errors.full_messages
      render :show, status: :unprocessable_entity
    end
  end

  private
    def init_errors
      @name_errors = []
      @password_errors = []
    end

    def name_params
      params.expect(user: [ :name ])
    end

    def password_params
      params.expect(user: [ :password, :password_confirmation ])
    end
end
