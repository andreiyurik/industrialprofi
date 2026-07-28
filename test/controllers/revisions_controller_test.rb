require "test_helper"

class RevisionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:pteep)
    @lesson.revise!(section: "body", html: "<p>Версия один</p>",
                    editor_name: "Иван", edit_reason: "первая правка", source: "suggestion")
    @revision = @lesson.lesson_revisions.ordered.first
  end

  test "index lists the lesson's revisions grouped by day" do
    get lesson_revisions_path(@lesson)
    assert_response :success
    assert_match "первая правка", response.body
    assert_match "Иван", response.body
    assert_match I18n.t("revisions.dates.today"), response.body
  end

  test "index is paginated and offers show more past one page" do
    25.times { |i| @lesson.revise!(section: "body", html: "<p>v#{i}</p>", editor_name: "A", edit_reason: nil, source: "admin") }
    get lesson_revisions_path(@lesson)
    assert_response :success
    assert_match I18n.t("revisions.show_more"), response.body
  end

  test "show more appends the next page as a turbo stream, not a full render" do
    25.times { |i| @lesson.revise!(section: "body", html: "<p>v#{i}</p>", editor_name: "A", edit_reason: nil, source: "admin") }
    cursor = @lesson.lesson_revisions.ordered.limit(RevisionsController::PER_PAGE).to_a.last.version

    get lesson_revisions_path(@lesson, before: cursor), as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %r{<turbo-stream action="append" target="revisions_list">}, response.body
    assert_match %r{<turbo-stream action="replace" target="revisions_more">}, response.body
  end

  test "show renders the diff for a revision" do
    get lesson_revision_path(@lesson, @revision)
    assert_response :success
    assert_select "div.revision-diff ins", text: "Версия"
  end

  test "index credits community-added sources by contributor name" do
    @lesson.resources.create!(title: "Src", url: "https://x.ru", kind: "norm",
      origin: "human", contributor_name: "Аня", position: 99)

    get lesson_revisions_path(@lesson)
    assert_response :success
    assert_match I18n.t("revisions.sources_credited"), response.body
    assert_match "Аня", response.body
  end

  test "index of an untouched lesson renders the empty state for guests" do
    untouched = lessons(:gruppy_dopuska)
    get lesson_revisions_path(untouched)
    assert_response :success
    assert_match I18n.t("revisions.none"), response.body
  end

  test "revisions of an unpublished lesson are not found" do
    paths(:electrician).update!(status: "draft")
    get lesson_revisions_path(@lesson)
    assert_response :not_found
  end
end
