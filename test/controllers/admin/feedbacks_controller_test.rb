require "test_helper"

module Admin
  class FeedbacksControllerTest < ActionDispatch::IntegrationTest
    test "members and editors cannot read the founder's inbox" do
      sign_in_as users(:member)
      get admin_feedbacks_url
      assert_redirected_to root_url

      sign_in_as users(:editor)
      get admin_feedbacks_url
      assert_redirected_to root_url
    end

    test "admin sees messages and opening the inbox marks them read" do
      sign_in_as users(:admin)
      assert Feedback.unread.any?

      get admin_feedbacks_url

      assert_response :success
      assert_match feedbacks(:unread_message).body, response.body
      assert_empty Feedback.unread
    end
  end
end
