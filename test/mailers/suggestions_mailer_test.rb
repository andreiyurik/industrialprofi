require "test_helper"

class SuggestionsMailerTest < ActionMailer::TestCase
  test "outcome for an approved edit links the lesson history" do
    suggestion = users(:member).lesson_suggestions.create!(
      lesson: lessons(:pteep), section: "body", author_name: "Иван",
      body_markdown: "Уточнение", status: "approved", reviewed_at: Time.current
    )

    email = SuggestionsMailer.outcome(suggestion)

    assert_equal [ users(:member).email_address ], email.to
    assert_includes email.subject, "принята"
    assert_includes email.subject, suggestion.lesson.title
    assert_match "/revisions", email.html_part.body.to_s
    assert_match "/unsubscribe/", email.html_part.body.to_s
    assert_match "kind=suggestions", email.header["List-Unsubscribe"].value
  end

  test "outcome for a rejected edit carries the reviewer's comment" do
    suggestion = users(:member).lesson_suggestions.create!(
      lesson: lessons(:pteep), section: "body", author_name: "Иван",
      body_markdown: "Уточнение", status: "rejected", reviewed_at: Time.current,
      reviewer_comment: "Формулировка расходится с ПУЭ."
    )

    email = SuggestionsMailer.outcome(suggestion)

    assert_includes email.subject, "не принята"
    assert_match suggestion.reviewer_comment, email.html_part.body.to_s
    assert_match suggestion.reviewer_comment, email.text_part.body.to_s
  end

  test "review digest lists the pending queue for the reviewer's professions" do
    email = SuggestionsMailer.review_digest(users(:editor))

    assert_equal [ users(:editor).email_address ], email.to
    assert_match lesson_suggestions(:pending_suggestion).author_name, email.html_part.body.to_s
    assert_no_match lesson_suggestions(:welder_suggestion).author_name, email.html_part.body.to_s
    assert_match "/admin/lesson_suggestions", email.html_part.body.to_s
    assert_match "List-Unsubscribe=One-Click", email.header["List-Unsubscribe-Post"].value
  end
end
