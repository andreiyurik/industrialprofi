require "test_helper"

class Admin::RevisionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @lesson = lessons(:pteep)
    @lesson.revise!(section: "body", html: "<p>Первая версия</p>", editor_name: "A", edit_reason: nil, source: "admin")
    @lesson.revise!(section: "body", html: "<p>Вторая версия</p>", editor_name: "A", edit_reason: nil, source: "admin")
  end

  test "index requires auth" do
    sign_out
    get admin_lesson_revisions_path(@lesson)
    assert_redirected_to new_session_path
  end

  test "index lists revisions" do
    get admin_lesson_revisions_path(@lesson)
    assert_response :success
    assert_match I18n.t("revisions.rollback"), response.body
  end

  test "rollback restores a past version as a new revision" do
    target = @lesson.lesson_revisions.find_by(version: 1)

    assert_difference -> { @lesson.lesson_revisions.count }, 1 do
      post rollback_admin_lesson_revision_path(@lesson, target)
    end

    assert_includes @lesson.reload.section_html(:body), "Первая версия"
    newest = @lesson.lesson_revisions.ordered.first
    assert_equal "rollback", newest.source
    assert_equal 3, newest.version
    assert_redirected_to admin_lesson_revisions_path(@lesson)
  end
end
