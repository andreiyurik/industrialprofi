class SessionsController < ApplicationController
  require_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: t("auth.rate_limited") }

  # A guest who was about to do something signed-in (take a map, build their
  # own version) carries where to come back to; anything but a path of our own
  # is ignored, so the link can never bounce someone off-site.
  def new
    session[:return_to_after_authenticating] = params[:return_to] if params[:return_to]&.match?(%r{\A/[^/\\]})
  end

  def create
    if user = User.active.authenticate_by(email_address: params[:email_address], password: params[:password])
      start_new_session_for user
      redirect_to post_authenticating_url
    else
      flash.now[:alert] = t("auth.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_current_session
    redirect_to root_path, notice: t("auth.signed_out")
  end
end
