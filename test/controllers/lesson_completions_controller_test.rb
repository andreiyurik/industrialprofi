require "test_helper"

class LessonCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:pteep)
  end

  test "requires authentication" do
    post lesson_completion_path(@lesson)
    assert_redirected_to new_session_path
  end

  test "create marks the lesson as completed" do
    sign_in_as users(:member)

    assert_difference -> { users(:member).lesson_completions.count }, 1 do
      post lesson_completion_path(@lesson)
    end
    assert_redirected_to lesson_path(@lesson)
  end

  test "create responds with turbo stream updates for button and sidebar" do
    sign_in_as users(:member)

    post lesson_completion_path(@lesson), as: :turbo_stream
    assert_response :success
    assert_match "completion_lesson_#{@lesson.id}", response.body
    assert_match "lesson_sidebar", response.body
    assert_match I18n.t("lessons.completed"), response.body
  end

  test "create is idempotent" do
    sign_in_as users(:member)
    users(:member).lesson_completions.create!(lesson: @lesson)

    assert_no_difference -> { LessonCompletion.count } do
      post lesson_completion_path(@lesson)
    end
  end

  test "destroy removes the completion" do
    sign_in_as users(:member)
    users(:member).lesson_completions.create!(lesson: @lesson)

    assert_difference -> { LessonCompletion.count }, -1 do
      delete lesson_completion_path(@lesson)
    end
  end

  test "cannot complete a lesson of an unpublished path" do
    sign_in_as users(:member)

    assert_no_difference -> { LessonCompletion.count } do
      post lesson_completion_path(lessons(:draft_lesson))
    end
    assert_response :not_found
  end
end
