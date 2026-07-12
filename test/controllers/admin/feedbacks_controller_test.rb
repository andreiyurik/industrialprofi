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

    # ── One-gesture coauthor approval ──

    test "the inbox prefills the approve form with the applicant's named profession" do
      sign_in_as users(:admin)
      get admin_feedbacks_url
      assert_select "form[action=?] input[name=profession_title][value=?]",
        approve_coauthor_admin_feedback_path(feedbacks(:coauthor_application)), "Агроном"
    end

    test "approving creates the draft profession, promotes the applicant, grants and logs it" do
      sign_in_as users(:admin)
      applicant = users(:member)

      assert_difference [ -> { Path.count }, -> { applicant.editorships.count } ], 1 do
        assert_difference -> { AdminAction.where(action: "coauthor_approved").count }, 1 do
          assert_enqueued_emails 1 do
            post approve_coauthor_admin_feedback_url(feedbacks(:coauthor_application)),
              params: { profession_title: "Агроном" }
          end
        end
      end

      path = Path.find_by!(title: "Агроном")
      assert_equal applicant.id, path.author_id
      assert_equal "draft", path.status
      assert_equal "agronom", path.slug
      assert_equal "editor", applicant.reload.role
      assert applicant.can_edit_path?(path)
      assert_redirected_to edit_admin_path_path(path)
      assert feedbacks(:coauthor_application).reload.read_at.present?
    end

    test "approving without a profession name is refused and creates nothing" do
      sign_in_as users(:admin)
      assert_no_difference -> { Path.count } do
        post approve_coauthor_admin_feedback_url(feedbacks(:coauthor_application)),
          params: { profession_title: "  " }
      end
      assert_redirected_to admin_feedbacks_path
    end

    test "a double approval lands on the same draft instead of duplicating it" do
      sign_in_as users(:admin)
      post approve_coauthor_admin_feedback_url(feedbacks(:coauthor_application)),
        params: { profession_title: "Агроном" }

      assert_no_difference -> { Path.count } do
        post approve_coauthor_admin_feedback_url(feedbacks(:coauthor_application)),
          params: { profession_title: "Агроном" }
      end
      assert_redirected_to edit_admin_path_path(Path.find_by!(title: "Агроном"))
    end

    test "an ordinary feedback cannot be approved as a coauthor application" do
      sign_in_as users(:admin)
      assert_no_difference -> { Path.count } do
        post approve_coauthor_admin_feedback_url(feedbacks(:unread_message)),
          params: { profession_title: "Что-нибудь" }
      end
      assert_response :not_found
    end

    test "editors cannot approve coauthor applications" do
      sign_in_as users(:editor)
      assert_no_difference -> { Path.count } do
        post approve_coauthor_admin_feedback_url(feedbacks(:coauthor_application)),
          params: { profession_title: "Агроном" }
      end
      assert_redirected_to root_url
    end
  end
end
