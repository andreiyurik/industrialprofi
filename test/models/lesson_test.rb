require "test_helper"

class LessonTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    lesson = Lesson.new(path: paths(:electrician), title: "Новый урок", slug: "novyy-urok")
    assert lesson.valid?
  end

  test "invalid without title" do
    lesson = Lesson.new(path: paths(:electrician), slug: "no-title")
    assert_not lesson.valid?
    assert lesson.errors[:title].any?
  end

  test "invalid without slug" do
    lesson = Lesson.new(path: paths(:electrician), title: "No Slug")
    assert_not lesson.valid?
    assert lesson.errors[:slug].any?
  end

  test "invalid without path" do
    lesson = Lesson.new(title: "Orphan", slug: "orphan")
    assert_not lesson.valid?
    assert lesson.errors[:path].any?
  end

  test "slug must be unique" do
    lesson = Lesson.new(path: paths(:electrician), title: "Dup", slug: lessons(:pteep).slug)
    assert_not lesson.valid?
    assert lesson.errors[:slug].any?
  end

  test "slug rejects invalid format" do
    lesson = Lesson.new(path: paths(:electrician), title: "Test", slug: "BAD SLUG")
    assert_not lesson.valid?
    assert lesson.errors[:slug].any?
  end

  test "position must be non-negative" do
    lesson = Lesson.new(path: paths(:electrician), title: "Test", slug: "neg-pos", position: -1)
    assert_not lesson.valid?
    assert lesson.errors[:position].any?
  end

  # Associations

  test "belongs to path" do
    assert_equal paths(:electrician), lessons(:pteep).path
  end

  test "has many resources" do
    assert_equal 2, lessons(:pteep).resources.count
  end

  test "destroying lesson destroys resources" do
    assert_difference "Resource.count", -2 do
      lessons(:pteep).destroy
    end
  end

  # to_param

  test "to_param returns slug" do
    assert_equal "pteep-osnovy", lessons(:pteep).to_param
  end

  # to_markdown

  test "to_markdown includes body" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.body
  end

  test "to_markdown includes title as heading" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, "# #{lesson.title}"
  end

  test "to_markdown includes description" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.description
  end

  test "to_markdown includes task" do
    lesson = lessons(:pteep)
    md = lesson.to_markdown
    assert_includes md, lesson.task
  end

  test "to_markdown omits blank sections" do
    lesson = Lesson.new(path: paths(:electrician), title: "Minimal", slug: "minimal", body: "Content here")
    md = lesson.to_markdown
    assert_includes md, "Content here"
    refute_includes md, "Задание"
  end
end
