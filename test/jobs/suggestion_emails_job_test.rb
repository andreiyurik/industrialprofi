require "test_helper"

class SuggestionEmailsJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @member = users(:member)
    @editor = users(:editor)
  end

  # ── Outcome emails to suggestion authors ──

  test "emails an unseen decision exactly once" do
    suggestion = decided_suggestion(reviewed_at: 2.days.ago)

    assert_enqueued_emails 1 do
      SuggestionEmailsJob.perform_now
    end
    assert suggestion.reload.outcome_notified_at.present?

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
  end

  test "skips the email when the author already saw the decision in the app" do
    suggestion = decided_suggestion(reviewed_at: 2.days.ago)
    @member.update!(suggestions_seen_at: 1.day.ago)

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
    assert suggestion.reload.outcome_notified_at.present?, "loop already closed in-app"
  end

  test "skips the email when the author opted out" do
    suggestion = decided_suggestion(reviewed_at: 2.days.ago)
    @member.update!(suggestion_emails: false)

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
    assert suggestion.reload.outcome_notified_at.present?
  end

  test "leaves a fresh decision alone until the grace period passes" do
    suggestion = decided_suggestion(reviewed_at: 1.hour.ago)

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
    assert_nil suggestion.reload.outcome_notified_at
  end

  # ── Review digests to editors ──

  test "digests a stalled queue once per stall, scoped to granted professions" do
    lesson_suggestions(:pending_suggestion).update!(created_at: 3.days.ago)

    # The electrician suggestion stalls: the scoped editor and the admin each
    # get one digest; the second run stays silent.
    assert_enqueued_emails 2 do
      SuggestionEmailsJob.perform_now
    end
    assert @editor.reload.suggestion_digest_sent_at.present?

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
  end

  test "does not digest an editor for other professions' suggestions" do
    lesson_suggestions(:welder_suggestion).update!(created_at: 3.days.ago)

    # The welder suggestion is outside the electrician editor's grants —
    # only the admin (who reviews everything) is digested.
    assert_enqueued_emails 1 do
      SuggestionEmailsJob.perform_now
    end
    assert_nil @editor.reload.suggestion_digest_sent_at
  end

  test "skips the digest when the reviewer opted out" do
    lesson_suggestions(:welder_suggestion).update!(created_at: 3.days.ago)
    users(:admin).update!(suggestion_emails: false)

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
  end

  private

  def decided_suggestion(reviewed_at:)
    @member.lesson_suggestions.create!(
      lesson: lessons(:pteep), section: "body", author_name: @member.name,
      body_markdown: "Уточнение", status: "approved", reviewed_at: reviewed_at
    )
  end

  # ── Outcome emails to source proposers ──

  test "emails a decided source suggestion once" do
    suggestion = decided_resource_suggestion(reviewed_at: 2.days.ago)

    assert_enqueued_emails 1 do
      SuggestionEmailsJob.perform_now
    end
    assert suggestion.reload.outcome_notified_at.present?

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
  end

  test "skips the source email when the author already saw it in the app" do
    suggestion = decided_resource_suggestion(reviewed_at: 2.days.ago)
    @member.update!(suggestions_seen_at: 1.day.ago)

    assert_no_enqueued_emails do
      SuggestionEmailsJob.perform_now
    end
    assert suggestion.reload.outcome_notified_at.present?
  end

  def decided_resource_suggestion(reviewed_at:)
    @member.resource_suggestions.create!(
      lesson: lessons(:pteep), author_name: @member.name,
      url: "https://ya.ru/g", title: "ГОСТ Тест", kind: "norm",
      status: "approved", reviewed_at: reviewed_at
    )
  end
end
