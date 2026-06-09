require "test_helper"

class LessonSuggestionsControllerTest < ActionDispatch::IntegrationTest
  test "new returns success" do
    get new_lesson_suggestion_path(lesson_slug: lessons(:pteep).slug)
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "create with valid data redirects with notice" do
    assert_difference "LessonSuggestion.count", 1 do
      post lesson_suggestions_path(lessons(:pteep)), params: {
        lesson_suggestion: {
          section: "body",
          body_markdown: "Improved content here",
          author_name: "Test User",
          author_contact: "test@example.com"
        }
      }
    end
    assert_redirected_to lesson_path(lessons(:pteep))
    assert_equal I18n.t("flash.suggestion_submitted"), flash[:notice]
  end

  test "create captures the edit reason and a base snapshot" do
    post lesson_suggestions_path(lessons(:pteep)), params: {
      lesson_suggestion: {
        section: "body",
        body_markdown: "Improved content here",
        author_name: "Test User",
        edit_reason: "Поправил опечатку"
      }
    }
    suggestion = LessonSuggestion.order(:created_at).last
    assert_equal "Поправил опечатку", suggestion.edit_reason
    assert_includes suggestion.base_content, "Содержание урока по ПТЭЭП"
  end

  test "create without author_name re-renders form" do
    assert_no_difference "LessonSuggestion.count" do
      post lesson_suggestions_path(lessons(:pteep)), params: {
        lesson_suggestion: {
          body_markdown: "Content",
          author_name: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create without body_markdown re-renders form" do
    assert_no_difference "LessonSuggestion.count" do
      post lesson_suggestions_path(lessons(:pteep)), params: {
        lesson_suggestion: {
          body_markdown: "",
          author_name: "Author"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with filled honeypot is silently dropped" do
    assert_no_difference "LessonSuggestion.count" do
      post lesson_suggestions_path(lessons(:pteep)), params: {
        company: "spam-bot",
        lesson_suggestion: {
          section: "body",
          body_markdown: "Spam content",
          author_name: "Bot"
        }
      }
    end
    assert_redirected_to lesson_path(lessons(:pteep))
    assert_equal I18n.t("flash.suggestion_submitted"), flash[:notice]
  end
end
