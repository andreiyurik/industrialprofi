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

  test "index shows pending suggestions" do
    get admin_lesson_suggestions_path, headers: @credentials
    assert_response :success
    assert_match lesson_suggestions(:pending_suggestion).author_name, response.body
  end

  # Show

  test "show displays side-by-side comparison" do
    get admin_lesson_suggestion_path(lesson_suggestions(:pending_suggestion)), headers: @credentials
    assert_response :success
    assert_match lesson_suggestions(:pending_suggestion).body_markdown, response.body
  end

  # Approve

  test "approve updates lesson body and marks approved" do
    suggestion = lesson_suggestions(:pending_suggestion)
    original_body = suggestion.lesson.body

    patch approve_admin_lesson_suggestion_path(suggestion), headers: @credentials

    suggestion.reload
    assert_equal "approved", suggestion.status
    assert_not_equal original_body, suggestion.lesson.reload.body
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
