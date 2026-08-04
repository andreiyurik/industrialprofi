# Daily sweep (config/recurring.yml) closing the suggestion feedback loop by
# email — the Fizzy pattern: the app is the primary channel, mail goes only to
# people who didn't see the news there. The "should we email" judgment lives in
# LessonSuggestion#needs_outcome_email? and User#needs_suggestion_digest?.
class SuggestionEmailsJob < ApplicationJob
  queue_as :default

  def perform
    notify_authors
    notify_resource_authors
    notify_reviewers
  end

  private

  # Same close-the-loop rule as text edits, for proposed sources: one email per
  # decision after a day's grace, only if the author didn't see it in-app.
  def notify_resource_authors
    ResourceSuggestion.decided
                      .where(outcome_notified_at: nil, reviewed_at: ..ResourceSuggestion::OUTCOME_EMAIL_AFTER.ago)
                      .where.not(user_id: nil)
                      .includes(:user).find_each do |suggestion|
      SuggestionsMailer.resource_outcome(suggestion).deliver_later if suggestion.needs_outcome_email?
      suggestion.touch(:outcome_notified_at)
    end
  end

  # One email per decision, after a day's grace for the author to see it on
  # their dashboard. outcome_notified_at is set either way — seen in the app,
  # emailed, or consciously skipped — so a decision is handled exactly once.
  def notify_authors
    LessonSuggestion.decided
                    .where(outcome_notified_at: nil, reviewed_at: ..LessonSuggestion::OUTCOME_EMAIL_AFTER.ago)
                    .where.not(user_id: nil)
                    .includes(:user).find_each do |suggestion|
      SuggestionsMailer.outcome(suggestion).deliver_later if suggestion.needs_outcome_email?
      suggestion.touch(:outcome_notified_at)
    end
  end

  def notify_reviewers
    User.active.where(role: %w[editor administrator], suggestion_emails: true).find_each do |user|
      next unless user.needs_suggestion_digest?

      SuggestionsMailer.review_digest(user).deliver_later
      user.touch(:suggestion_digest_sent_at)
    end
  end
end
