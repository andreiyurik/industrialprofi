require "test_helper"

class GuestDraftLinksTest < ActionDispatch::IntegrationTest
  setup do
    @hidden = Lesson.publicly_visible.practice.joins(:path).merge(Path.in_catalog.localized).first!
    @hidden.update!(body: "![Фото](TODO-photo.png)")
    @hidden.course.update!(status: "draft")
  end

  test "no reader page links to a lesson in a draft chapter" do
    neighbour = Lesson.publicly_visible.where(path: @hidden.path).first!
    pages = [ projects_path, path_practice_path(@hidden.path), illustrations_path, path_path(@hidden.path), lesson_path(neighbour) ]

    pages.each do |page|
      get page

      assert_response :success
      assert_select "a[href=?]", lesson_path(@hidden), false, page
    end
  end

  test "previous and next skip draft chapters" do
    Lesson.publicly_visible.where(path: @hidden.path).includes(:path).find_each do |lesson|
      assert_not_includes [ lesson.prev_in_path, lesson.next_in_path ], @hidden
    end
  end
end
