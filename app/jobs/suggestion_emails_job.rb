class SuggestionEmailsJob < ApplicationJob
  queue_as :default

  def perform
    notify_authors
    notify_resource_authors
    notify_reviewers
  end

  private

  def notify_resource_authors
    ResourceSuggestion.decided
                      .where(outcome_notified_at: nil, reviewed_at: ..ResourceSuggestion::OUTCOME_EMAIL_AFTER.ago)
                      .where.not(user_id: nil)
                      .includes(:user).find_each do |suggestion|
      SuggestionsMailer.resource_outcome(suggestion).deliver_later if suggestion.needs_outcome_email?
      suggestion.touch(:outcome_notified_at)
    end
  end

  # outcome_notified_at is set whether the email sent or not, so each decision is handled once.
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
