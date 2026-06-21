class FeedbackMailer < ApplicationMailer
  def new_message(feedback)
    @feedback = feedback
    @user = feedback.user

    recipients = User.administrator.pluck(:email_address)
    return if recipients.empty?

    mail to: recipients,
         reply_to: @user.email_address,
         subject: t("feedback_mailer.new_message.subject", name: @user.name)
  end
end
