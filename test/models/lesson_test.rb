require "test_helper"

class LessonTest < ActiveSupport::TestCase
  # Validations

  test "valid with required attributes" do
    lesson = Lesson.new(course: courses(:el_basics), title: "Новый урок", slug: "novyy-urok")
    assert lesson.valid?
  end

  test "invalid without course" do
    lesson = Lesson.new(title: "Orphan", slug: "orphan")
    assert_not lesson.valid?
    assert lesson.errors[:course].any?
  end

  test "derives path from course" do
    lesson = Lesson.new(course: courses(:el_basics), title: "X", slug: "x-derives")
    lesson.valid?
    assert_equal paths(:electrician), lesson.path
  end

  test "invalid without title" do
    lesson = Lesson.new(path: paths(:electrician), slug: "no-title")
    assert_not lesson.valid?
    assert lesson.errors[:title].any?
  end

  test "auto-generates a slug from the title when blank" do
    lesson = Lesson.new(course: courses(:el_basics), title: "Новый Урок")
    assert lesson.valid?
    assert_equal "novyy-urok", lesson.slug
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

  test "belongs to course" do
    assert_equal courses(:el_basics), lessons(:pteep).course
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

  # missing_self_check? (drives content:audit)

  test "missing_self_check? is true for a written theory lesson without a self-check block" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-no-check",
                        body: "Объяснение темы без вопросов.")
    assert lesson.missing_self_check?
  end

  test "missing_self_check? is false when the body has a self-check block" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-with-check",
                        body: "Объяснение.\n\n> [!ПРОВЕРЬ] Что произойдёт, если...?")
    assert_not lesson.missing_self_check?
  end

  test "missing_self_check? is false for an unwritten lesson with no body yet" do
    lesson = Lesson.new(course: courses(:el_basics), title: "T", slug: "t-empty")
    assert_not lesson.missing_self_check?
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

  # Revisions

  test "section_html falls back to rendered markdown" do
    assert_includes lessons(:pteep).section_html(:body), "Содержание урока по ПТЭЭП"
  end

  test "revise! applies content and records a revision" do
    lesson = lessons(:pteep)

    assert_difference -> { lesson.lesson_revisions.count }, 1 do
      lesson.revise!(section: "body", html: "<p>Свежий текст</p>",
                     editor_name: "Автор", edit_reason: "почему", source: "suggestion")
    end

    assert_includes lesson.reload.section_html(:body), "Свежий текст"
    revision = lesson.lesson_revisions.ordered.first
    assert_equal 1, revision.version
    assert_equal "Автор", revision.editor_name
    assert_equal "почему", revision.edit_reason
    assert_includes revision.content_after, "Свежий текст"
  end

  test "revise! increments version numbers" do
    lesson = lessons(:pteep)
    lesson.revise!(section: "body", html: "<p>один</p>", editor_name: "A", edit_reason: nil, source: "admin")
    lesson.revise!(section: "body", html: "<p>два</p>", editor_name: "A", edit_reason: nil, source: "admin")
    assert_equal [ 1, 2 ], lesson.lesson_revisions.order(:version).map(&:version)
  end

  test "admin_update_with_revisions! records only changed sections" do
    lesson = lessons(:pteep)

    assert_difference -> { lesson.lesson_revisions.count }, 1 do
      lesson.admin_update_with_revisions!(
        { rich_body: "<p>Совсем новое содержание</p>" }, edit_reason: "правка"
      )
    end

    revision = lesson.lesson_revisions.ordered.first
    assert_equal "body", revision.section
    assert_equal "admin", revision.source
  end

  test "admin_update_with_revisions! skips unchanged sections" do
    lesson = lessons(:pteep)
    assert_no_difference -> { lesson.lesson_revisions.count } do
      lesson.admin_update_with_revisions!({ title: "Переименовано" }, edit_reason: nil)
    end
    assert_equal "Переименовано", lesson.reload.title
  end

  test "revised? reflects revision count" do
    lesson = lessons(:pteep)
    refute lesson.revised?
    lesson.revise!(section: "body", html: "<p>x</p>", editor_name: "A", edit_reason: nil, source: "admin")
    assert lesson.reload.revised?
  end
end
