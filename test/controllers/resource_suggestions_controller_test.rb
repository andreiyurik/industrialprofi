require "test_helper"

class ResourceSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup { @lesson = lessons(:pteep) }

  test "new requires an account" do
    get new_lesson_resource_suggestion_path(@lesson)
    assert_redirected_to new_session_path
  end

  test "a signed-in reader can open the form" do
    sign_in_as users(:member)
    get new_lesson_resource_suggestion_path(@lesson)
    assert_response :success
  end

  test "create stores a pending suggestion under the reader's name" do
    sign_in_as users(:member)

    assert_difference -> { ResourceSuggestion.pending.count }, 1 do
      post lesson_resource_suggestions_path(@lesson),
        params: { resource_suggestion: {
          url: "https://ya.ru/gost", title: "ГОСТ 1", kind: "norm", note: "гл.1"
        } }
    end

    assert_redirected_to lesson_path(@lesson)
    suggestion = ResourceSuggestion.last
    assert_equal users(:member).id, suggestion.user_id
    assert_equal users(:member).name, suggestion.author_name
    assert_equal "pending", suggestion.status
  end

  test "an invalid submission re-renders the form" do
    sign_in_as users(:member)
    post lesson_resource_suggestions_path(@lesson),
      params: { resource_suggestion: { url: "", title: "", kind: "norm" } }
    assert_response :unprocessable_entity
  end
end
