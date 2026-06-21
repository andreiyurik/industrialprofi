require "test_helper"

class RemindersMailerTest < ActionMailer::TestCase
  test "continue_learning points at the next lesson and carries unsubscribe" do
    user = users(:member)
    user.lesson_completions.create!(lesson: lessons(:pteep), created_at: 10.days.ago)
    next_lesson = user.next_lesson_in(user.focus_path)

    email = RemindersMailer.continue_learning(user)

    assert_equal [ user.email_address ], email.to
    assert_match next_lesson.title, email.subject
    [ email.text_part, email.html_part ].each do |part|
      assert_match "/lessons/#{next_lesson.slug}", part.body.to_s
      assert_match "/unsubscribe/", part.body.to_s
    end
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].to_s
  end
end
