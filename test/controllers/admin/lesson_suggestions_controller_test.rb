require "test_helper"

class Admin::LessonSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @credentials = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") }
  end

  # Auth

  test "index without auth returns 401" do
    get admin_lesson_suggestions_path
    assert_response :unauthorized
  end

  # Index

  test "index shows pending suggestions grouped by lesson" do
    get admin_lesson_suggestions_path, headers: @credentials
    assert_response :success
    assert_match lesson_suggestions(:pending_suggestion).author_name, response.body
    assert_match lesson_suggestions(:pending_suggestion).lesson.title, response.body
  end

  # Show

  test "show displays an inline diff and the edit reason" do
    suggestion = lesson_suggestions(:pending_suggestion)
    get admin_lesson_suggestion_path(suggestion), headers: @credentials
    assert_response :success
    assert_select "div.revision-diff ins", text: "Предложенное"
    assert_match suggestion.edit_reason, response.body
  end

  # Approve

  test "approve applies the edit and records a revision" do
    suggestion = lesson_suggestions(:pending_suggestion)

    assert_difference -> { suggestion.lesson.lesson_revisions.count }, 1 do
      patch approve_admin_lesson_suggestion_path(suggestion), headers: @credentials
    end

    suggestion.reload
    assert_equal "approved", suggestion.status
    assert_includes suggestion.lesson.section_html(:body), suggestion.body_markdown

    revision = suggestion.lesson.lesson_revisions.ordered.first
    assert_equal "suggestion", revision.source
    assert_equal suggestion.author_name, revision.editor_name
    assert_equal suggestion.edit_reason, revision.edit_reason
    assert_equal suggestion.id, revision.lesson_suggestion_id
    assert_redirected_to admin_lesson_suggestions_path
  end

  # Reject

  test "reject changes status and saves comment" do
    suggestion = lesson_suggestions(:pending_suggestion)

    patch reject_admin_lesson_suggestion_path(suggestion),
      params: { lesson_suggestion: { reviewer_comment: "Not accurate" } },
      headers: @credentials

    suggestion.reload
    assert_equal "rejected", suggestion.status
    assert_equal "Not accurate", suggestion.reviewer_comment
    assert_redirected_to admin_lesson_suggestions_path
  end
end
