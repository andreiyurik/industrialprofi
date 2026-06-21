require "test_helper"

class LearningReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users(:member)
    @user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 10.days.ago)
  end

  test "nudges a stalled learner exactly once per stall" do
    assert_enqueued_emails 1 do
      LearningReminderJob.perform_now
    end
    assert @user.reload.reminded_at.present?

    assert_no_enqueued_emails do
      LearningReminderJob.perform_now
    end
  end

  test "skips learners who opted out" do
    @user.update!(reminder_emails: false)

    assert_no_enqueued_emails do
      LearningReminderJob.perform_now
    end
  end

  test "skips recently active learners" do
    @user.lesson_completions.create!(lesson: lessons(:gruppy_dopuska), created_at: 1.day.ago)

    assert_no_enqueued_emails do
      LearningReminderJob.perform_now
    end
  end
end
