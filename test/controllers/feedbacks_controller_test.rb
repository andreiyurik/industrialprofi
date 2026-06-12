require "test_helper"

class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "requires authentication" do
    get new_feedback_url
    assert_redirected_to new_session_url
  end

  test "signed-in user sends a message and the founder is notified" do
    sign_in_as users(:member)

    assert_enqueued_emails 1 do
      assert_difference "Feedback.count", 1 do
        post feedbacks_url, params: { feedback: { body: "Отличный проект, добавьте КИПиА!", page_url: "http://localhost/paths/elektrik" } }
      end
    end

    assert_redirected_to dashboard_url
    feedback = Feedback.newest_first.first
    assert_equal users(:member), feedback.user
    assert_nil feedback.read_at
  end

  test "rejects an empty message" do
    sign_in_as users(:member)

    assert_no_difference "Feedback.count" do
      post feedbacks_url, params: { feedback: { body: "" } }
    end
    assert_response :unprocessable_entity
  end
end
