class RemindersMailer < ApplicationMailer
  def continue_learning(user)
    @user = user
    @path = user.focus_path
    @lesson = user.next_lesson_in(@path)
    @unsubscribe_url = unsubscribe_url(user.generate_token_for(:email_unsubscribe))

    # RFC 8058 one-click unsubscribe — mail clients show their own
    # "Unsubscribe" button, and deliverability improves.
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    mail to: user.email_address,
         subject: t("reminders_mailer.continue_learning.subject", lesson: @lesson.title)
  end
end
