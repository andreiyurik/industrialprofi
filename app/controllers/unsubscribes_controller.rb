# One-click unsubscribe — reached from an email link, so no login required and
# the token alone is the authorization. ?kind= picks which emails to stop;
# links without it (all reminder emails ever sent) keep working.
class UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  # The RFC 8058 one-click POST comes from the mail provider without a CSRF token.
  skip_forgery_protection

  KINDS = { "reminders" => :reminder_emails, "suggestions" => :suggestion_emails }.freeze

  def show
    @user = unsubscribe
  end

  # List-Unsubscribe-Post target — a machine is calling, no page to render.
  def create
    unsubscribe
    head :ok
  end

  private
    def unsubscribe
      user = User.find_by_token_for(:email_unsubscribe, params[:token])
      user&.update!(KINDS.fetch(params[:kind], :reminder_emails) => false)
      user
    end
end
