class UsersController < ApplicationController
  require_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_user_path, alert: t("auth.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to dashboard_path, notice: t("auth.welcome", name: @user.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
    end
end
