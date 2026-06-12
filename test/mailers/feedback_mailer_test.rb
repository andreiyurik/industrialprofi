require "test_helper"

class FeedbackMailerTest < ActionMailer::TestCase
  test "new_message goes to admins with reply-to set to the sender" do
    feedback = feedbacks(:unread_message)

    email = FeedbackMailer.new_message(feedback)

    assert_equal [ users(:admin).email_address ], email.to
    assert_equal [ feedback.user.email_address ], email.reply_to
    assert_match feedback.user.name, email.subject
    assert_match feedback.body, email.text_part.body.to_s
  end
end
