require "test_helper"

class RevisionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:pteep)
    @lesson.revise!(section: "body", html: "<p>Версия один</p>",
                    editor_name: "Иван", edit_reason: "первая правка", source: "suggestion")
    @revision = @lesson.lesson_revisions.ordered.first
  end

  test "index lists the lesson's revisions" do
    get lesson_revisions_path(@lesson)
    assert_response :success
    assert_match "первая правка", response.body
    assert_match "Иван", response.body
  end

  test "index is paginated and offers show more" do
    12.times { |i| @lesson.revise!(section: "body", html: "<p>v#{i}</p>", editor_name: "A", edit_reason: nil, source: "admin") }
    get lesson_revisions_path(@lesson)
    assert_response :success
    assert_match I18n.t("revisions.show_more"), response.body
  end

  test "show renders the diff for a revision" do
    get lesson_revision_path(@lesson, @revision)
    assert_response :success
    assert_select "div.revision-diff ins", text: "Версия"
  end

  test "revisions of an unpublished lesson are not found" do
    paths(:electrician).update!(status: "draft")
    get lesson_revisions_path(@lesson)
    assert_response :not_found
  end
end
