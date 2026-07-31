require "test_helper"

class Admin::CoauthorApprovalsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "approving creates the draft profession, promotes the applicant, grants and logs it" do
    sign_in_as users(:admin)
    applicant = users(:member)

    assert_difference [ -> { Path.count }, -> { applicant.editorships.count } ], 1 do
      assert_difference -> { AdminAction.where(action: "coauthor_approved").count }, 1 do
        assert_enqueued_emails 1 do
          post admin_feedback_coauthor_approval_url(feedbacks(:coauthor_application)),
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
      post admin_feedback_coauthor_approval_url(feedbacks(:coauthor_application)),
        params: { profession_title: "  " }
    end
    assert_redirected_to admin_feedbacks_path
  end

  test "a double approval lands on the same draft instead of duplicating it" do
    sign_in_as users(:admin)
    post admin_feedback_coauthor_approval_url(feedbacks(:coauthor_application)),
      params: { profession_title: "Агроном" }

    assert_no_difference -> { Path.count } do
      post admin_feedback_coauthor_approval_url(feedbacks(:coauthor_application)),
        params: { profession_title: "Агроном" }
    end
    assert_redirected_to edit_admin_path_path(Path.find_by!(title: "Агроном"))
  end

  test "an ordinary feedback cannot be approved as a coauthor application" do
    sign_in_as users(:admin)
    assert_no_difference -> { Path.count } do
      post admin_feedback_coauthor_approval_url(feedbacks(:unread_message)),
        params: { profession_title: "Что-нибудь" }
    end
    assert_response :not_found
  end

  test "editors cannot approve coauthor applications" do
    sign_in_as users(:editor)
    assert_no_difference -> { Path.count } do
      post admin_feedback_coauthor_approval_url(feedbacks(:coauthor_application)),
        params: { profession_title: "Агроном" }
    end
    assert_redirected_to root_url
  end
end
