require "test_helper"

class ResourceLibraryTest < ActiveSupport::TestCase
  test "dedupes by URL, counts referencing lessons, required wins if any" do
    course = courses(:el_basics) # published course in the published electrician path
    url = "https://example.com/shared-standard"
    a = course.lessons.create!(title: "Lib Lesson A", slug: "lib-lesson-a", stage: "S", kind: "lesson")
    b = course.lessons.create!(title: "Lib Lesson B", slug: "lib-lesson-b", stage: "S", kind: "lesson")
    a.resources.create!(title: "ГОСТ Общий", url:, kind: "document", required: false)
    b.resources.create!(title: "ГОСТ Общий", url:, kind: "document", required: true)

    entry = ResourceLibrary.for(path: paths(:electrician)).find { |e| e.url == url }
    assert_not_nil entry
    assert_equal 2, entry.lesson_count, "one entry per URL, counting both lessons"
    assert entry.required?, "required if ANY referencing resource is required"
  end

  test "merges same-title entries under different URLs and strips authoring notes" do
    course = courses(:el_basics)
    a = course.lessons.create!(title: "Merge A", slug: "merge-a", stage: "S", kind: "lesson")
    b = course.lessons.create!(title: "Merge B", slug: "merge-b", stage: "S", kind: "lesson")
    a.resources.create!(title: "ГОСТ 12345 Тест", url: "https://example.com/a", kind: "document", required: true)
    b.resources.create!(title: "ГОСТ 12345 Тест (для аудита)", url: "https://example.com/b", kind: "document", required: false)

    matches = ResourceLibrary.for(path: paths(:electrician)).select { |e| e.title.include?("ГОСТ 12345 Тест") }
    assert_equal 1, matches.size, "same title under different URLs collapses to one entry"
    assert_equal "ГОСТ 12345 Тест", matches.first.title, "the authoring note is stripped from display"
    assert matches.first.required?, "required if any merged source is required"
  end

  test "excludes resources from unpublished content" do
    draft_lesson = courses(:draft_course).lessons.create!(
      title: "Draft Lib Lesson", slug: "draft-lib-lesson", stage: "S", kind: "lesson"
    )
    draft_lesson.resources.create!(title: "Невидимый ГОСТ", url: "https://example.com/hidden", kind: "document")

    assert_not_includes ResourceLibrary.for.map(&:url), "https://example.com/hidden"
  end

  test "version stamps the live set and changes when it grows" do
    before = ResourceLibrary.version
    courses(:el_basics).lessons.first.resources.create!(
      title: "Свежий ГОСТ", url: "https://example.com/fresh", kind: "document"
    )
    assert_not_equal before, ResourceLibrary.version,
      "adding a live resource must bust the shared hub stamp"
  end

  test "a shared version yields the same entries as a per-path key" do
    path = paths(:electrician)
    assert_equal ResourceLibrary.for(path:).map(&:url),
                 ResourceLibrary.for(path:, version: ResourceLibrary.version).map(&:url),
      "the version only changes the cache key, never the built entries"
  end

  test "ranks required resources ahead of optional ones" do
    course = courses(:el_basics)
    lesson = course.lessons.create!(title: "Rank Lesson", slug: "rank-lesson", stage: "S", kind: "lesson")
    lesson.resources.create!(title: "Необязательная книга", url: "https://example.com/opt", kind: "article", required: false)
    lesson.resources.create!(title: "Обязательный стандарт", url: "https://example.com/req", kind: "document", required: true)

    entries = ResourceLibrary.for(path: paths(:electrician))
    req_index = entries.index { |e| e.url == "https://example.com/req" }
    opt_index = entries.index { |e| e.url == "https://example.com/opt" }
    assert req_index < opt_index, "required entries sort before optional ones"
  end
end
