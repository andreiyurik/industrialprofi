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

    # ── Filtered view (dashboard signal target) ──

    test "the coauthor filter shows only applications and leaves general messages unread" do
      sign_in_as users(:admin)
      get admin_feedbacks_url(only: "coauthor")

      assert_response :success
      assert_match "12 лет в поле", response.body
      assert_no_match(/не открывается вторая ссылка/, response.body)
      # It read the applications it showed, but not the general inbox behind it.
      assert feedbacks(:coauthor_application).reload.read_at.present?
      assert_nil feedbacks(:unread_message).reload.read_at
    end

    # ── One-gesture coauthor approval (form rendering only — the approval
    # itself is Admin::CoauthorApprovalsController, see its own test) ──

    test "the inbox prefills the approve form with the applicant's named profession" do
      sign_in_as users(:admin)
      get admin_feedbacks_url
      assert_select "form[action=?] input[name=profession_title][value=?]",
        admin_feedback_coauthor_approval_path(feedbacks(:coauthor_application)), "Агроном"
    end
  end
end
