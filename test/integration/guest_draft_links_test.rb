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

  test "a signed-in reader's dashboard and the guide skip draft chapters" do
    reader = users(:member)
    reader.lesson_bookmarks.create!(lesson: @hidden)
    reader.lesson_completions.create!(lesson: Lesson.publicly_visible.where(path: @hidden.path).first!)
    @hidden.update_columns(slug: PagesController::REFERENCE_LESSON_SLUGS.first, position: 0)
    sign_in_as reader

    [ dashboard_path, guide_path ].each do |page|
      get page

      assert_response :success
      assert_select "a[href=?]", lesson_path(@hidden), false, page
      assert_select "a[href=?]", course_path(@hidden.course), false, page
    end
  end

  test "a draft preview still walks to its neighbours" do
    first, second = Lesson.publicly_visible.where(path: @hidden.path).ordered.first(2)
    @hidden.path.update!(status: "draft")

    assert_equal second, first.reload.next_in_path
  end

  test "previous and next skip draft chapters" do
    Lesson.publicly_visible.where(path: @hidden.path).includes(:course, :path).find_each do |lesson|
      assert_not_includes [ lesson.prev_in_path, lesson.next_in_path ], @hidden
    end
  end
end
