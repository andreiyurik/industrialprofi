class Signups::CompletionsController < ApplicationController
  include SignupFlow

  before_action :ensure_verified_signup

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(email_address: signup.email_address))

    if @user.save
      signup.clear!
      start_new_session_for @user
      flash[:welcome_letter] = true
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def ensure_verified_signup
      if !signup.pending?
        redirect_to new_signup_path
      elsif !signup.verified?
        redirect_to new_signup_verification_path
      end
    end

    def user_params
      params.expect(user: [ :name, :password, :password_confirmation ])
    end
end
