require "test_helper"

class CurriculumDocumentTest < ActiveSupport::TestCase
  DOC = <<~YAML.freeze
    path:
      title: "Сантехник"
      description: "Профессия сантехника."
      status: published
    courses:
      - title: "Основы"
        sections:
          - title: "Введение"
            lessons:
              - title: "Что делает сантехник"
                kind: lesson
                description: "Зачем."
                body: "Тело урока."
                resources:
                  - title: "ГОСТ 1"
                    url: "https://example.com/g1"
                    kind: document
                    required: true
              - title: "Первая практика"
                kind: practice
  YAML

  test "imports a new profession as a draft, stamped ai, owned by the author" do
    author = users(:editor)
    document = CurriculumDocument.parse(DOC)
    assert document.valid?, document.errors.inspect

    result = nil
    assert_difference -> { Path.count }, 1 do
      result = document.import!(author: author)
    end

    path = result.path
    assert_equal "Сантехник", path.title
    assert_equal "draft", path.status, "AI imports must land as draft, never published"
    assert_equal "ai", path.origin
    assert_equal author.id, path.author_id
    assert_equal "santehnik", path.slug

    course = path.courses.sole
    assert_equal "draft", course.status
    assert_equal "ai", course.origin

    lessons = path.lessons.order(:position)
    assert_equal 2, lessons.size
    assert_equal "Введение", lessons.first.stage
    assert_equal "ai", lessons.first.origin
    assert_equal "beginner", lessons.last.difficulty, "a practice lesson gets a default difficulty"

    resource = lessons.first.resources.sole
    assert_equal "ai", resource.origin
    assert resource.required?
  end

  test "plan is a dry run that writes nothing but reports the counts" do
    document = CurriculumDocument.parse(DOC)
    plan = nil
    assert_no_difference %w[Path.count Course.count Lesson.count Resource.count] do
      plan = document.plan(author: users(:admin))
    end
    assert_equal 1, plan.counts[:courses]
    assert_equal 2, plan.counts[:lessons]
    assert_equal 1, plan.counts[:resources]
    assert_equal :new, plan.path_node[:status]
  end

  test "an existing path slug is reused, never overwritten, but new children are added" do
    yaml = <<~YAML
      path:
        title: "Электрик переписанный"
        slug: "elektrik"
      courses:
        - title: "Совсем новый курс"
          slug: "absolutely-new-course"
          sections:
            - title: "Раздел"
              lessons:
                - title: "Новый урок отсюда"
    YAML
    before_title = paths(:electrician).title

    result = CurriculumDocument.parse(yaml).import!(author: users(:admin))

    assert_equal paths(:electrician), result.path
    assert_equal :exists, result.path_node[:status]
    assert_equal before_title, paths(:electrician).reload.title, "existing path must not be overwritten"
    assert Course.exists?(slug: "absolutely-new-course"), "new course is still added under the existing path"
  end

  test "blank, path-less, and malformed input are invalid" do
    assert_not CurriculumDocument.parse("").valid?
    assert_not CurriculumDocument.parse("courses: []").valid?
    assert_not CurriculumDocument.parse("path: [broken").valid?
  end
end
