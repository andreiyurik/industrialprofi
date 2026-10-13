require "test_helper"

class IllustrationSuggestionsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { @lesson = lessons(:pteep) }

  test "requires authentication" do
    get new_lesson_illustration_suggestion_url(@lesson)
    assert_redirected_to new_session_url
  end

  test "a signed-in reader sees the form with the brief" do
    sign_in_as users(:member)
    get new_lesson_illustration_suggestion_url(@lesson, brief: "Щит с открытой дверцей")
    assert_response :success
    assert_match "Щит с открытой дверцей", response.body
  end

  test "a suggestion is stored as a feedback on the lesson and the founder is notified" do
    sign_in_as users(:member)

    assert_enqueued_emails 1 do
      assert_difference "Feedback.count", 1 do
        post lesson_illustration_suggestion_url(@lesson), params: { illustration_suggestion: {
          brief: "Щит с открытой дверцей", link: "https://commons.wikimedia.org/wiki/File:Panel.jpg", note: "Снято у меня на объекте"
        } }
      end
    end

    assert_redirected_to lesson_url(@lesson)
    feedback = Feedback.newest_first.first
    assert_equal users(:member), feedback.user
    assert_equal lesson_path(@lesson), feedback.page_url
    assert_match I18n.t("illustration_suggestions.message.header"), feedback.body
    assert_match @lesson.title, feedback.body
    assert_match "File:Panel.jpg", feedback.body
  end

  test "a suggestion without a link is rejected" do
    sign_in_as users(:member)
    assert_no_difference "Feedback.count" do
      post lesson_illustration_suggestion_url(@lesson), params: { illustration_suggestion: { link: "", note: "x" } }
    end
    assert_response :unprocessable_entity
  end

  test "a lesson in an unpublished profession is not found" do
    sign_in_as users(:member)
    get new_lesson_illustration_suggestion_url(lessons(:draft_lesson))
    assert_response :not_found
  end
end
