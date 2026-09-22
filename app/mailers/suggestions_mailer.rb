class SuggestionsMailer < ApplicationMailer
  def outcome(suggestion)
    @suggestion = suggestion
    @user = suggestion.user
    @lesson = suggestion.lesson
    unsubscribe_headers_for(@user)

    mail to: @user.email_address,
         subject: t("suggestions_mailer.outcome.subject_#{suggestion.status}", lesson: @lesson.title)
  end

  def resource_outcome(suggestion)
    @suggestion = suggestion
    @user = suggestion.user
    @lesson = suggestion.lesson
    unsubscribe_headers_for(@user)

    mail to: @user.email_address,
         subject: t("suggestions_mailer.resource_outcome.subject_#{suggestion.status}", lesson: @lesson.title)
  end

  def review_digest(user)
    @user = user
    @pending = user.reviewable_suggestions.pending.includes(:lesson).order(:created_at)
    unsubscribe_headers_for(user)

    mail to: user.email_address,
         subject: t("suggestions_mailer.review_digest.subject", count: @pending.size)
  end

  private

  def unsubscribe_headers_for(user)
    @unsubscribe_url = unsubscribe_url(user.generate_token_for(:email_unsubscribe), kind: "suggestions")

    # RFC 8058 one-click unsubscribe — mail clients show their own button for it.
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
