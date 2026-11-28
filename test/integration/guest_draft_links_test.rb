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

    assert_not_nil second
    assert_equal second, first.reload.next_in_path
  end

  test "a cached lesson page revalidates when the next chapter is drafted" do
    @hidden.course.update!(status: "published")
    chapter_start = @hidden.course.lessons.ordered.first
    lesson = @hidden.path.lessons.where("position < ?", chapter_start.position).ordered.last
    assert_not_nil lesson
    assert_not_equal @hidden.course_id, lesson.course_id
    get lesson_path(lesson)
    assert_response :success
    etag = response.headers["ETag"]

    travel 1.minute do
      @hidden.course.update!(status: "draft")
      get lesson_path(lesson), headers: { "If-None-Match" => etag }
    end

    assert_response :success
    assert_select "a[href=?]", lesson_path(@hidden), false
  end

  test "the dashboard counts only visible lessons and the path milestone ignores drafts" do
    reader = users(:member)
    visible = Lesson.publicly_visible.where(path: @hidden.path).to_a
    visible.each { |lesson| reader.lesson_completions.find_or_create_by!(lesson:) }

    assert_equal :path, reader.milestone_reached_for(visible.last, completed_ids: reader.completed_lesson_ids)
    sign_in_as reader
    get dashboard_path

    assert_response :success
    assert_select ".progress--done"
  end

  test "journal and profile lists and the practice picker skip draft chapters" do
    reader = users(:member)
    reader.journal_entries.create!(title: "Запись", body: "x", lesson: @hidden)
    sign_in_as reader

    get journal_entries_path
    assert_select "a[href=?]", lesson_path(@hidden), false

    assert_not_includes Path.published.localized.with_practice_lessons.flat_map(&:practice_lessons), @hidden
    assert_not_includes reader.improved_lessons, @hidden
  end

  test "previous and next skip draft chapters" do
    Lesson.publicly_visible.where(path: @hidden.path).includes(:course, :path).find_each do |lesson|
      assert_not_includes [ lesson.prev_in_path, lesson.next_in_path ], @hidden
    end
  end
end
