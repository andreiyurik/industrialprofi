require "test_helper"

class Admin::LessonSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # Auth

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_lesson_suggestions_path
    assert_redirected_to new_session_path
  end

  # Index

  test "index shows pending suggestions grouped by lesson" do
    get admin_lesson_suggestions_path
    assert_response :success
    assert_match lesson_suggestions(:pending_suggestion).author_name, response.body
    assert_match lesson_suggestions(:pending_suggestion).lesson.title, response.body
  end

  # Show

  test "show displays an inline diff and the edit reason" do
    suggestion = lesson_suggestions(:pending_suggestion)
    get admin_lesson_suggestion_path(suggestion)
    assert_response :success
    assert_select "div.revision-diff ins", text: "Предложенное"
    assert_match suggestion.edit_reason, response.body
  end

  test "show offers a side-by-side view and a diff toggle" do
    get admin_lesson_suggestion_path(lesson_suggestions(:pending_suggestion))
    assert_response :success
    assert_select ".segmented__tab", 2                         # two view tabs
    assert_select ".review-split .review-pane", 2              # current | proposed
    assert_select ".review-pane__head--current"
    assert_select ".review-pane__head--proposed"
  end

  # Approve

  test "approve applies the edit and records a revision" do
    suggestion = lesson_suggestions(:pending_suggestion)

    assert_difference -> { suggestion.lesson.lesson_revisions.count }, 1 do
      patch approve_admin_lesson_suggestion_path(suggestion)
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

  test "inline approve from the queue responds with a Turbo Stream, no reload" do
    suggestion = lesson_suggestions(:pending_suggestion)

    assert_difference -> { suggestion.lesson.lesson_revisions.count }, 1 do
      patch approve_admin_lesson_suggestion_path(suggestion), params: { inline: true }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "approved", suggestion.reload.status
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %r{target="suggestions"}, response.body          # queue re-rendered in place
    assert_match %r{target="admin_suggestions_count"}, response.body # nav badge refreshed
  end

  # Reject

  test "reject changes status and saves comment" do
    suggestion = lesson_suggestions(:pending_suggestion)

    patch reject_admin_lesson_suggestion_path(suggestion),
      params: { lesson_suggestion: { reviewer_comment: "Not accurate" } }

    suggestion.reload
    assert_equal "rejected", suggestion.status
    assert_equal "Not accurate", suggestion.reviewer_comment
    assert_redirected_to admin_lesson_suggestions_path
  end

  # Per-profession access (editorships)

  test "an editor's queue holds only suggestions for their granted professions" do
    sign_out
    sign_in_as users(:editor)
    get admin_lesson_suggestions_path
    assert_response :success
    assert_match lesson_suggestions(:pending_suggestion).author_name, response.body # electrician — granted
    assert_no_match(/#{lesson_suggestions(:welder_suggestion).author_name}/, response.body) # welder — not
  end

  test "an editor cannot approve a suggestion in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    assert_no_difference -> { lesson_suggestions(:welder_suggestion).lesson.lesson_revisions.count } do
      patch approve_admin_lesson_suggestion_path(lesson_suggestions(:welder_suggestion))
    end
    assert_redirected_to admin_lessons_path
    assert_equal "pending", lesson_suggestions(:welder_suggestion).reload.status
  end
end
