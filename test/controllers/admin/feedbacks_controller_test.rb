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

    test "the inbox paginates once it overflows one page" do
      sign_in_as users(:admin)
      per = Admin::FeedbacksController::PER_PAGE
      per.times { |i| Feedback.create!(user: users(:member), body: "сообщение #{i}") }

      get admin_feedbacks_url
      assert_response :success
      assert_select ".inbox__item", per, "first page is capped at PER_PAGE"
      assert_select ".admin-pagination"

      get admin_feedbacks_url(page: 2)
      assert_response :success
      assert_select ".inbox__item", minimum: 1
    end
  end
end
