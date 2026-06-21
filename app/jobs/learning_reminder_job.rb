# Daily sweep (config/recurring.yml) for stalled learners. All the "should we
# email this person" judgment lives in User#needs_learning_reminder? — this job
# only iterates and records that the nudge was sent.
class LearningReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.where(reminder_emails: true).find_each do |user|
      next unless user.needs_learning_reminder?

      RemindersMailer.continue_learning(user).deliver_later
      user.touch(:reminded_at)
    end
  end
end
