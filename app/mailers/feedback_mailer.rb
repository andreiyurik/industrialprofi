class FeedbackMailer < ApplicationMailer
  def new_message(feedback)
    @feedback = feedback
    @user = feedback.user

    recipients = User.administrator.pluck(:email_address)
    return if recipients.empty?

    options = { to: recipients }
    if @user
      options[:reply_to] = @user.email_address
      options[:subject] = t("feedback_mailer.new_message.subject", name: @user.name)
    else
      # Guest business inquiry — the sender's contact lives in the body.
      options[:subject] = t("feedback_mailer.new_message.guest_subject")
    end
    mail(**options)
  end

  private
    # Here @user is the SENDER; the letter goes to the founder.
    def recipient_locale
      I18n.default_locale
    end
end
