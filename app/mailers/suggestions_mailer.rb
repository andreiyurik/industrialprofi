class SuggestionsMailer < ApplicationMailer
  # The decision on a reader's suggested edit — sent only when the author
  # didn't see it in the app first (SuggestionEmailsJob).
  def outcome(suggestion)
    @suggestion = suggestion
    @user = suggestion.user
    @lesson = suggestion.lesson
    unsubscribe_headers_for(@user)

    mail to: @user.email_address,
         subject: t("suggestions_mailer.outcome.subject_#{suggestion.status}", lesson: @lesson.title)
  end

  # The decision on a reader's proposed source — same in-app-first rule as
  # #outcome, but a link has no revision to view, so it points back to the lesson.
  def resource_outcome(suggestion)
    @suggestion = suggestion
    @user = suggestion.user
    @lesson = suggestion.lesson
    unsubscribe_headers_for(@user)

    mail to: @user.email_address,
         subject: t("suggestions_mailer.resource_outcome.subject_#{suggestion.status}", lesson: @lesson.title)
  end

  # Pending edits that waited too long in this reviewer's queue — one digest
  # per stall (User#needs_suggestion_digest?), never a drip.
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

    # RFC 8058 one-click unsubscribe — mail clients show their own
    # "Unsubscribe" button, and deliverability improves.
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
