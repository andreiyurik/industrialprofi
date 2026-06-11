require "test_helper"

class LessonBookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:praktika_shchitok)
  end

  test "requires authentication" do
    post lesson_bookmark_path(@lesson)
    assert_redirected_to new_session_path
  end

  test "create saves the bookmark" do
    sign_in_as users(:member)

    assert_difference -> { users(:member).lesson_bookmarks.count }, 1 do
      post lesson_bookmark_path(@lesson)
    end
    assert_redirected_to lesson_path(@lesson)
  end

  test "create is idempotent" do
    sign_in_as users(:member)
    users(:member).lesson_bookmarks.create!(lesson: @lesson)

    assert_no_difference -> { LessonBookmark.count } do
      post lesson_bookmark_path(@lesson)
    end
  end

  test "destroy removes the bookmark" do
    sign_in_as users(:member)
    users(:member).lesson_bookmarks.create!(lesson: @lesson)

    assert_difference -> { users(:member).lesson_bookmarks.count }, -1 do
      delete lesson_bookmark_path(@lesson)
    end
  end

  test "create responds with a turbo stream flipping the toggle to saved" do
    sign_in_as users(:member)

    post lesson_bookmark_path(@lesson), as: :turbo_stream
    assert_response :success
    assert_match "bookmark_lesson_#{@lesson.id}", response.body
    assert_match "bookmark-btn--on", response.body
  end

  test "destroy turbo stream removes the dashboard row and empty section" do
    sign_in_as users(:member)
    users(:member).lesson_bookmarks.create!(lesson: @lesson)

    delete lesson_bookmark_path(@lesson), as: :turbo_stream
    assert_response :success
    assert_match "bookmark_row_lesson_#{@lesson.id}", response.body
    assert_match "dashboard_bookmarks", response.body # last bookmark → section goes too
  end

  test "unpublished lessons cannot be bookmarked" do
    sign_in_as users(:member)
    post lesson_bookmark_path(lessons(:draft_lesson))
    assert_response :not_found
  end

  test "completing a lesson removes its bookmark" do
    sign_in_as users(:member)
    users(:member).lesson_bookmarks.create!(lesson: @lesson)

    assert_difference -> { users(:member).lesson_bookmarks.count }, -1 do
      post lesson_completion_path(@lesson)
    end
  end
end
